# Super Liquid Soccer Modloader

Modloader e mods para a versão web do **Super Liquid Soccer** — agora com uma base avançada que já inclui a Copa do Mundo de 2026 e um modo multiplayer casual para dois jogadores.

> Projeto experimental/meme para jogar com amigos. A publicação planejada é pelo GitHub Pages.

## O que já funciona

- Base avançada do jogo em Godot 3.5.1.
- Copa 2026 com 48 seleções, 12 grupos e mata-mata.
- Seleções novas com jogadores atuais e históricos.
- Modloader com validação, aplicação, verificação e restauração de mods.
- Multiplayer 1×1 com sala, senha e nickname.
- Publicação automática da build web pelo GitHub Pages.

## Jogar localmente

É necessário usar um servidor HTTP porque o navegador bloqueia alguns recursos quando o jogo é aberto diretamente pelo explorador de arquivos.

```powershell
cd game3
py -m http.server 8000
```

Depois abra:

- Jogo normal: `http://localhost:8000/index-mod.html`
- Multiplayer: `http://localhost:8000/multiplayer.html`

No multiplayer, o anfitrião cria a sala e escolhe os dois times no jogo. O segundo jogador entra com o mesmo nome de sala e senha e controla o time visitante com:

| Ação | Tecla |
| --- | --- |
| Movimento | Setas |
| Passe | `H` |
| Chute | `J` |
| Lançamento/slide | `K` |
| Passe em profundidade | `L` |
| Corrida | `U` |
| Trocar jogador | `I` |

O multiplayer usa WebRTC/PeerJS para conectar os jogadores. O anfitrião executa a partida e transmite a tela, mantendo a sincronização simples para esse projeto pequeno.

## Modloader

O mod multiplayer é o padrão do comando `apply`:

```powershell
py modloader.py list
py modloader.py validate
py modloader.py apply
py modloader.py verify
```

Para escolher outro mod, informe o caminho do manifesto:

```powershell
py modloader.py apply mods/super-mod-soccer
```

## Estrutura

```text
.
├── game3/                 # Build web publicada
│   ├── multiplayer.html   # Lobby multiplayer
│   └── multiplayer.js    # Sinalização, WebRTC e controles
├── mods/                  # Mods instaláveis
├── source/
│   ├── advanced/          # Base avançada recuperada
│   └── vanilla/           # Base original recuperada
├── tools/                 # Ferramentas de recuperação/compilação
├── modloader.py           # CLI do modloader
└── .github/workflows/     # Publicação automática no Pages
```

## Publicar no GitHub Pages

O workflow publica automaticamente o conteúdo de `game3/` a cada push na branch `main`.

No repositório do GitHub, selecione **Settings → Pages → Source: GitHub Actions**. Depois do primeiro push, o endereço do Pages aparecerá na execução do workflow.

## Roadmap

- Mostrar nicknames dentro da partida.
- Melhorar feedback de conexão e reconexão.
- Criar uma tela de seleção de times dentro do lobby.
- Adicionar novos mods sem precisar editar a build manualmente.

## Status

Projeto em desenvolvimento. O foco atual é uma experiência simples e divertida para duas pessoas, não uma infraestrutura competitiva ou um servidor dedicado.
