(function () {
  "use strict";

  const $ = (id) => document.getElementById(id);
  const game = $("game");
  const video = $("remoteVideo");
  const lobby = $("lobby");
  const status = $("status");
  const controls = $("controls");
  const hostGame = $("hostGame");
  const peerIdFor = (room) => {
    let hash = 2166136261;
    for (const char of room.trim().toLowerCase()) {
      hash ^= char.charCodeAt(0);
      hash = Math.imul(hash, 16777619);
    }
    return "sls-" + (hash >>> 0).toString(36);
  };

  let peer = null;
  let connection = null;
  let host = false;
  let streamStarted = false;
  const pressed = new Set();
  const keys = new Set(["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "KeyH", "KeyJ", "KeyK", "KeyL", "KeyU", "KeyI", "KeyO"]);

  function setStatus(message) {
    status.textContent = message;
  }

  function values() {
    const nickname = $("nickname").value.trim();
    const room = $("room").value.trim();
    const password = $("password").value;
    if (!nickname || !room || !password) {
      setStatus("Preencha nickname, sala e senha.");
      return null;
    }
    return { nickname, room, password };
  }

  function openHostGame() {
    lobby.style.display = "none";
    game.style.display = "block";
    hostGame.style.display = "block";
  }

  function send(message) {
    if (connection && connection.open) connection.send(message);
  }

  function keyboardEvent(code, down) {
    const frame = game.contentWindow;
    const target = game.contentDocument && game.contentDocument.querySelector("canvas");
    if (!frame || !target) return;
    const key = code.startsWith("Key") ? code.slice(3).toLowerCase() : code;
    const event = new frame.KeyboardEvent(down ? "keydown" : "keyup", {
      key, code, bubbles: true, cancelable: true
    });
    const keyCode = code === "ArrowUp" ? 38 : code === "ArrowDown" ? 40 : code === "ArrowLeft" ? 37 : code === "ArrowRight" ? 39 : key.toUpperCase().charCodeAt(0);
    Object.defineProperty(event, "keyCode", { get: () => keyCode });
    Object.defineProperty(event, "which", { get: () => keyCode });
    target.dispatchEvent(event);
    frame.dispatchEvent(event);
  }

  function startHostStream() {
    if (!host || streamStarted || !connection || !connection.open) return;
    const canvas = game.contentDocument && game.contentDocument.querySelector("canvas");
    if (!canvas || !canvas.captureStream) return;
    streamStarted = true;
    const stream = canvas.captureStream(30);
    const call = peer.call(connection.peer, stream);
    call.on("error", () => { streamStarted = false; });
    setStatus("Amigo conectado: " + (connection.remoteNickname || "jogador") + ".");
  }

  function pollHostStream() {
    if (host && !streamStarted) startHostStream();
    if (host) window.setTimeout(pollHostStream, 800);
  }

  function setupConnection(conn, info) {
    connection = conn;
    conn.on("open", () => {
      conn.send({ type: "hello", nickname: info.nickname, password: info.password });
      setStatus("Conectando à sala...");
    });
    conn.on("data", (message) => {
      if (!message || typeof message !== "object") return;
      if (host && message.type === "hello") {
        if (message.password !== info.password) {
          conn.send({ type: "error", message: "Senha incorreta." });
          window.setTimeout(() => conn.close(), 200);
          return;
        }
        conn.remoteNickname = message.nickname;
        conn.send({ type: "welcome", nickname: info.nickname });
        $("hostHelp").style.display = "block";
        $("continue").style.display = "block";
        setStatus("" + message.nickname + " entrou na sala.");
        startHostStream();
      } else if (!host && message.type === "welcome") {
        setStatus("Conectado com " + message.nickname + ". Aguardando a partida...");
      } else if (!host && message.type === "error") {
        setStatus(message.message);
      } else if (host && message.type === "key") {
        keyboardEvent(message.code, message.down);
      }
    });
    conn.on("close", () => {
      setStatus("A conexão foi encerrada.");
      streamStarted = false;
    });
    conn.on("error", () => setStatus("Não foi possível manter a conexão."));
  }

  function setupPeer(info, isHost) {
    host = isHost;
    const id = isHost ? peerIdFor(info.room) : undefined;
    peer = new Peer(id);
    peer.on("open", (peerId) => {
      if (isHost) {
        game.src = "index-mod.html?mp=host";
        setStatus("Sala criada. Compartilhe o nome e a senha com seu amigo.");
        pollHostStream();
      } else {
        const conn = peer.connect(peerIdFor(info.room), { reliable: true });
        setupConnection(conn, info);
      }
    });
    peer.on("connection", (conn) => {
      if (isHost && !connection) setupConnection(conn, info);
      else conn.close();
    });
    peer.on("call", (call) => {
      if (!isHost) {
        call.answer();
        call.on("stream", (remoteStream) => {
          video.srcObject = remoteStream;
          video.style.display = "block";
          game.style.display = "none";
          lobby.style.display = "none";
          controls.style.display = "block";
        });
      }
    });
    peer.on("error", (error) => {
      const message = error.type === "unavailable-id" ? "Essa sala já existe." : "Falha na conexão: " + error.type;
      setStatus(message);
    });
  }

  $("create").addEventListener("click", () => {
    const info = values();
    if (!info) return;
    $("create").disabled = true;
    $("join").disabled = true;
    setupPeer(info, true);
  });

  $("join").addEventListener("click", () => {
    const info = values();
    if (!info) return;
    $("create").disabled = true;
    $("join").disabled = true;
    setupPeer(info, false);
  });

  $("continue").addEventListener("click", openHostGame);
  hostGame.addEventListener("click", () => { lobby.style.display = "block"; });

  document.addEventListener("keydown", (event) => {
    if (host || !keys.has(event.code) || pressed.has(event.code)) return;
    pressed.add(event.code);
    event.preventDefault();
    send({ type: "key", code: event.code, down: true });
  });
  document.addEventListener("keyup", (event) => {
    if (host || !keys.has(event.code)) return;
    pressed.delete(event.code);
    event.preventDefault();
    send({ type: "key", code: event.code, down: false });
  });
})();
