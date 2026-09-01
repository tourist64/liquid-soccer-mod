# Super Liquid Soccer Modloader

Modloader e mods para a versão web do **Super Liquid Soccer** — agora com uma base avançada que já inclui a Copa do Mundo de 2026 e um modo multiplayer casual para dois jogadores.

> Projeto experimental/meme para jogar com amigos. A publicação planejada é pelo GitHub Pages.

## O que já funciona

- Base avançada do jogo em Godot 3.5.1.
- Copa 2026 com 48 seleções, 12 grupos e mata-mata.
- Seleções novas com jogadores atuais e históricos.
- Modloader com validação, aplicação, verificação, restauração e detecção de conflitos.
- Multiplayer 1×1 com sala, senha e nickname.
- Publicação automática da build web pelo GitHub Pages.

## Jogar localmente

É necessário usar um servidor HTTP porque o navegador bloqueia alguns recursos quando o jogo é aberto diretamente pelo explorador de arquivos.

```powershell
py tools/dev_server.py --port 8000
```

Depois abra:

- Jogo normal: `http://localhost:8000/index-mod.html`
- O multiplayer fica no próprio menu do jogo, no botão `Multiplayer`.

O servidor local salva os logs do multiplayer em `game3/multiplayer.log`. Para acompanhar em tempo real em outro terminal PowerShell:

```powershell
Get-Content .\game3\multiplayer.log -Wait
```

Esses logs são apenas para desenvolvimento local e não são usados no GitHub Pages.

No multiplayer, o anfitrião cria a sala, o segundo jogador entra com o mesmo nome e senha, e os dois seguem o fluxo normal do jogo para escolher os times. O visitante controla o segundo time com:

| Ação | Tecla |
| --- | --- |
| Movimento | Setas |
| Passe | `H` |
| Chute | `J` |
| Lançamento/slide | `K` |
| Passe em profundidade | `L` |
| Corrida | `U` |
| Trocar jogador | `I` |

O multiplayer usa sinalização HTTP por polling e WebRTC nativo para conectar os jogadores. O anfitrião executa a partida e transmite a tela, mantendo a sincronização simples para esse projeto pequeno.

O multiplayer usa sinalização HTTP por polling e WebRTC nativo, sem depender do PeerJS público. No modo local, o servidor do jogo encaminha `/signal` para o servidor de sinalização na porta 9000. Para iniciar os dois processos:

```powershell
py tools/dev_server.py --port 8000
$env:PORT=9000; node multiplayer-server/server.js
```

Para jogar com alguém fora do computador, publique `multiplayer-server/` em um host HTTPS; GitHub Pages serve os arquivos, mas não executa o servidor de sinalização.

Existe um servidor mínimo pronto em `multiplayer-server/` para hospedar na Discloud ou em outro host Node:

```bash
cd multiplayer-server
npm install
npm start
```

Para a Discloud, envie apenas a pasta `multiplayer-server/`, que já contém `discloud.config`. Depois, defina `window.SLS_SIGNAL_SERVER` em `game3/multiplayer-config.js` com a URL HTTPS desse servidor, por exemplo `"https://seu-app.discloud.app"`. A documentação da Discloud exige `TYPE=site` e porta `8080` para aplicações externas: [Websites & APIs](https://docs.discloud.com/en/how-to-host/websites-and-apis).

Durante o desenvolvimento local, o botão `Logs` mostra o diagnóstico do polling e `game3/multiplayer.log` recebe as mesmas linhas.

## Testes locais

Os testes não precisam abrir o jogo nem usar duas abas. Eles validam o protocolo multiplayer e as regras de conflito do modloader:

```powershell
node --test tests/multiplayer-protocol.test.js tests/multiplayer-server.test.js
py -m unittest discover -s tests -p "test_*.py" -v
```

Antes de publicar uma build, valide também o pacote aplicado:

```powershell
py modloader.py validate
py modloader.py apply
py modloader.py verify
```

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

A Copa do Mundo de 2026 já faz parte da base avançada, então não existe mais um mod separado para ela. Para conferir conflitos entre mods instalados:

```powershell
py modloader.py conflicts
```

O modloader também aceita mais de uma mod no `apply`, mas interrompe a aplicação se elas alterarem o mesmo recurso. Assim, nenhuma mod sobrescreve outra silenciosamente.

## Estrutura

```text
.
├── game3/                 # Build web publicada
│   └── multiplayer-bridge.js # Sinalização, WebRTC e controles do modo interno
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
- Adicionar novos mods sem precisar editar a build manualmente.

## Status

Projeto em desenvolvimento. O foco atual é uma experiência simples e divertida para duas pessoas, não uma infraestrutura competitiva ou um servidor dedicado.
