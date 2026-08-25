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
py modloader.py validate mods/multiplayer
py modloader.py apply mods/multiplayer
py modloader.py verify mods/multiplayer
```

## Multiplayer

O MVP multiplayer fica em `game3/multiplayer.html`. Ele usa uma sala P2P com nickname e senha, transmite a tela do anfitrião e envia os controles do segundo jogador. O jogo continua hospedado no GitHub Pages; o PeerJS é usado somente para sinalização e WebRTC.

Abra `http://localhost:8000/multiplayer.html` depois de iniciar o servidor dentro de `game3`. O anfitrião escolhe os dois times no jogo e o convidado controla o segundo time com as setas, `H`, `J`, `K`, `L`, `U` e `I`.
