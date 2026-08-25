# Super Liquid Soccer Modloader

Modloader e mods para a versão web do Super Liquid Soccer.

## Estrutura

- `game3/`: build web atual e arquivos publicados.
- `mods/`: mods instaláveis pelo modloader.
- `source/advanced/`: projeto recuperado da versão avançada com a Copa 2026.
- `source/vanilla/`: projeto recuperado da versão original.
- `tools/`: scripts de geração e compilação usados no desenvolvimento.
- `modloader.py`: aplica, verifica e restaura mods no PCK.

## Rodar localmente

Na pasta `game3`, inicie um servidor HTTP e abra `index-mod.html` no navegador:

```powershell
py -m http.server 8000
```

O arquivo `game3/index-mod.pck` usa a base avançada e o mod `super-mod-soccer`, que identifica o modloader no título.

## Comandos do modloader

```powershell
py modloader.py list
py modloader.py validate mods/super-mod-soccer
py modloader.py apply mods/super-mod-soccer
py modloader.py verify mods/super-mod-soccer
```

## Multiplayer

O plano é um modo 1 contra 1 com sala, senha e escolha de seleção. O GitHub Pages hospedará o jogo; a conexão entre jogadores deverá usar WebRTC com uma camada externa simples de sinalização, pois o Pages não mantém salas por conta própria.
