from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import struct
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parent
DEFAULT_GAME_DIR = ROOT / "game3"
DEFAULT_MODS_DIR = ROOT / "mods"
BACKUP_NAME = ".index.pck.vanilla"
MODDED_PCK_NAME = "index-mod.pck"
MODDED_WASM_NAME = "index-mod.wasm"
MODDED_HTML_NAME = "index-mod.html"
HEADER_SIZE = 88
ALIGNMENT = 16


class ModloaderError(Exception):        
    pass


@dataclass
class PckEntry:
    path: str
    data: bytes


def align(value: int, boundary: int = ALIGNMENT) -> int:
    return (value + boundary - 1) // boundary * boundary


def atomic_write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        try:
            os.replace(temporary, path)
        except PermissionError:
            # Windows pode bloquear o rename enquanto o antivírus inspeciona um PCK grande.
            shutil.copyfile(temporary, path)
            os.unlink(temporary)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def read_pck(path: Path) -> tuple[bytes, list[PckEntry]]:
    raw = path.read_bytes()
    if len(raw) < HEADER_SIZE or raw[:4] != b"GDPC":
        raise ModloaderError(f"PCK inválido: {path}")

    count = struct.unpack_from("<I", raw, 84)[0]
    cursor = HEADER_SIZE
    entries: list[PckEntry] = []
    for index in range(count):
        if cursor + 4 > len(raw):
            raise ModloaderError(f"Tabela PCK truncada no item {index}")
        path_length = struct.unpack_from("<I", raw, cursor)[0]
        cursor += 4
        end_path = cursor + path_length
        if end_path > len(raw):
            raise ModloaderError(f"Caminho PCK truncado no item {index}")
        resource_path = raw[cursor:end_path].rstrip(b"\0").decode("utf-8")
        cursor = end_path
        if cursor + 32 + 16 > len(raw):
            raise ModloaderError(f"Metadados PCK truncados no item {index}")
        offset, size = struct.unpack_from("<QQ", raw, cursor)
        cursor += 16
        cursor += 16  # MD5 original; será recalculado ao reempacotar.
        if offset + size > len(raw):
            raise ModloaderError(f"Dados fora do arquivo para {resource_path}")
        entries.append(PckEntry(resource_path, raw[offset : offset + size]))
    return raw[:HEADER_SIZE], entries


def write_pck(path: Path, header: bytes, entries: list[PckEntry]) -> None:
    header = bytearray(header)
    struct.pack_into("<I", header, 84, len(entries))
    table_size = sum(4 + len(entry.path.encode("utf-8")) + 1 + 16 + 16 for entry in entries)
    data_cursor = align(HEADER_SIZE + table_size)
    locations: list[tuple[int, int]] = []
    for entry in entries:
        locations.append((data_cursor, len(entry.data)))
        data_cursor = align(data_cursor + len(entry.data))

    table = bytearray()
    for entry, (offset, size) in zip(entries, locations):
        encoded_path = entry.path.encode("utf-8") + b"\0"
        table.extend(struct.pack("<I", len(encoded_path)))
        table.extend(encoded_path)
        table.extend(struct.pack("<QQ", offset, size))
        table.extend(hashlib.md5(entry.data).digest())

    output = bytearray(header)
    output.extend(table)
    output.extend(b"\0" * (locations[0][0] - len(output)))
    for entry, (offset, _) in zip(entries, locations):
        if len(output) < offset:
            output.extend(b"\0" * (offset - len(output)))
        output.extend(entry.data)
        output.extend(b"\0" * (align(len(output)) - len(output)))
    atomic_write(path, bytes(output))


def load_manifest(mod_dir: Path) -> dict:
    manifest_path = mod_dir / "mod.json"
    if not manifest_path.is_file():
        raise ModloaderError(f"Mod sem mod.json: {mod_dir}")
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise ModloaderError(f"mod.json inválido: {error}") from error

    required = ("id", "name", "version", "game")
    if any(not manifest.get(field) for field in required):
        raise ModloaderError(f"mod.json precisa de: {', '.join(required)}")
    if manifest["game"] != "SuperLiquidSoccer":
        raise ModloaderError("Esta primeira versão aceita apenas SuperLiquidSoccer")
    if not isinstance(manifest["patches"], list):
        raise ModloaderError("patches precisa ser uma lista")
    for patch in manifest["patches"]:
        if not all(isinstance(patch.get(field), str) and patch[field] for field in ("path", "find", "replace")):
            raise ModloaderError("Cada patch precisa de path, find e replace")
        if not patch["path"].startswith("res://"):
            raise ModloaderError(f"Caminho de recurso inválido: {patch['path']}")
        if not isinstance(patch.get("count", 1), int) or patch.get("count", 1) < 1:
            raise ModloaderError("count precisa ser um inteiro positivo")
    if not isinstance(manifest.get("files", []), list):
        raise ModloaderError("files precisa ser uma lista")
    if not manifest["patches"] and not manifest.get("files"):
        raise ModloaderError("A mod precisa ter pelo menos um patch ou arquivo")
    for file_entry in manifest.get("files", []):
        if not all(isinstance(file_entry.get(field), str) and file_entry[field] for field in ("path", "source")):
            raise ModloaderError("Cada arquivo precisa de path e source")
        if not file_entry["path"].startswith("res://"):
            raise ModloaderError(f"Caminho de recurso inválido: {file_entry['path']}")
        if not (mod_dir / file_entry["source"]).is_file():
            raise ModloaderError(f"Arquivo da mod não encontrado: {file_entry['source']}")
        if not isinstance(file_entry.get("overwrite", False), bool):
            raise ModloaderError("overwrite precisa ser booleano")
    return manifest


def validate_patches(entries: list[PckEntry], manifest: dict, *, expect_replacement: bool = False) -> list[str]:
    by_path = {entry.path: entry for entry in entries}
    changes: list[str] = []
    for patch in manifest["patches"]:
        entry = by_path.get(patch["path"])
        if entry is None:
            raise ModloaderError(f"Recurso não encontrado no PCK: {patch['path']}")
        try:
            text = entry.data.decode("utf-8")
        except UnicodeDecodeError as error:
            raise ModloaderError(f"Recurso não é texto UTF-8: {patch['path']}") from error
        needle = patch["replace"] if expect_replacement else patch["find"]
        occurrences = text.count(needle)
        expected = patch.get("count", 1)
        if occurrences != expected:
            state = "modificado" if expect_replacement else "compatível"
            raise ModloaderError(
                f"Patch {patch['path']} não está {state}: esperado {expected}, encontrado {occurrences}"
            )
        changes.append(f"{patch['path']}: {expected} ocorrência(s)")
    return changes


def validate_files(entries: list[PckEntry], manifest: dict, mod_dir: Path) -> list[str]:
    by_path = {entry.path: entry for entry in entries}
    changes: list[str] = []
    for file_entry in manifest.get("files", []):
        entry = by_path.get(file_entry["path"])
        if entry is None:
            raise ModloaderError(f"Arquivo adicionado não encontrado no PCK: {file_entry['path']}")
        expected = (mod_dir / file_entry["source"]).read_bytes()
        if entry.data != expected:
            raise ModloaderError(f"Arquivo adicionado diferente do mod: {file_entry['path']}")
        changes.append(f"{file_entry['path']}: arquivo adicionado")
    return changes


def apply_mod(game_dir: Path, mod_dir: Path) -> None:
    vanilla_pck = game_dir / "index.pck"
    pck = game_dir / MODDED_PCK_NAME
    backup = game_dir / BACKUP_NAME
    if not vanilla_pck.is_file():
        raise ModloaderError(f"Jogo não encontrado: {vanilla_pck}")
    manifest = load_manifest(mod_dir)
    if not backup.exists():
        shutil.copy2(vanilla_pck, backup)
    base_header, entries = read_pck(backup)
    validate_patches(entries, manifest)
    by_path = {entry.path: entry for entry in entries}
    for patch in manifest["patches"]:
        entry = by_path[patch["path"]]
        text = entry.data.decode("utf-8")
        entry.data = text.replace(patch["find"], patch["replace"], patch.get("count", 1)).encode("utf-8")
    for file_entry in manifest.get("files", []):
        resource_path = file_entry["path"]
        if resource_path in by_path:
            if not file_entry.get("overwrite", False):
                raise ModloaderError(f"Arquivo da mod já existe no PCK: {resource_path}")
            by_path[resource_path].data = (mod_dir / file_entry["source"]).read_bytes()
        else:
            entry = PckEntry(resource_path, (mod_dir / file_entry["source"]).read_bytes())
            entries.append(entry)
            by_path[resource_path] = entry
    write_pck(pck, base_header, entries)
    validate_patches(read_pck(pck)[1], manifest, expect_replacement=True)
    validate_files(read_pck(pck)[1], manifest, mod_dir)
    html = (game_dir / "index.html").read_text(encoding="utf-8")
    html = html.replace('"executable":"index"', '"executable":"index-mod"', 1)
    html = re.sub(r'"index\.pck":\d+', f'"index-mod.pck":{pck.stat().st_size}', html, count=1)
    html = re.sub(r'"index\.wasm":\d+', f'"index-mod.wasm":{(game_dir / "index.wasm").stat().st_size}', html, count=1)
    shutil.copy2(game_dir / "index.wasm", game_dir / MODDED_WASM_NAME)
    atomic_write(game_dir / MODDED_HTML_NAME, html.encode("utf-8"))
    print(f"Mod aplicada: {manifest['name']} ({manifest['version']})")
    print(f"Abra: {game_dir / MODDED_HTML_NAME}")


def restore_game(game_dir: Path) -> None:
    removed = []
    for path in (game_dir / MODDED_PCK_NAME, game_dir / MODDED_WASM_NAME, game_dir / MODDED_HTML_NAME):
        if path.exists():
            path.unlink()
            removed.append(path.name)
    if removed:
        print(f"Variante removida: {', '.join(removed)}")
    else:
        print("Nenhuma variante modded encontrada")


def list_mods(mods_dir: Path) -> None:
    found = False
    for mod_dir in sorted(mods_dir.iterdir() if mods_dir.is_dir() else []):
        if not mod_dir.is_dir() or not (mod_dir / "mod.json").is_file():
            continue
        found = True
        try:
            manifest = load_manifest(mod_dir)
            print(f"{manifest['id']}  {manifest['version']}  {manifest['name']}")
        except ModloaderError as error:
            print(f"{mod_dir.name}  INVÁLIDA  {error}")
    if not found:
        print("Nenhuma mod encontrada")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Modloader mínimo do Super Liquid Soccer")
    parser.add_argument("--game-dir", type=Path, default=DEFAULT_GAME_DIR)
    parser.add_argument("--mods-dir", type=Path, default=DEFAULT_MODS_DIR)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("validate", "apply", "verify"):
        command = commands.add_parser(name)
        command.add_argument("mod", type=Path, nargs="?", default=DEFAULT_MODS_DIR / "super-mod-soccer")
    commands.add_parser("list")
    commands.add_parser("restore")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "list":
            list_mods(args.mods_dir)
        elif args.command == "validate":
            manifest = load_manifest(args.mod)
            print(f"Mod válida: {manifest['name']} ({manifest['version']})")
        elif args.command == "apply":
            apply_mod(args.game_dir, args.mod)
        elif args.command == "verify":
            manifest = load_manifest(args.mod)
            entries = read_pck(args.game_dir / MODDED_PCK_NAME)[1]
            validate_patches(entries, manifest, expect_replacement=True)
            validate_files(entries, manifest, args.mod)
            print(f"Mod verificada: {manifest['name']}")
        elif args.command == "restore":
            restore_game(args.game_dir)
        return 0
    except (OSError, ModloaderError) as error:
        print(f"ERRO: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
