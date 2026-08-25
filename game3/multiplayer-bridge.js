(function () {
  "use strict";


  const state = {
    status: "Digite os dados da sala para começar.",
    busy: false,
    host: false,
    connected: false,
    started: false,
    guest: ""
  };
  const keys = new Set([
    "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight",
    "KeyH", "KeyJ", "KeyK", "KeyL", "KeyU", "KeyI", "KeyO"
  ]);
  let peer = null;
  let connection = null;
  let streamSent = false;
  let peerLoading = null;

  const peerIdFor = (room) => {
    let hash = 2166136261;
    for (const char of room.trim().toLowerCase()) {
      hash ^= char.charCodeAt(0);
      hash = Math.imul(hash, 16777619);
    }
    return "sls-" + (hash >>> 0).toString(36);
  };

  function setStatus(message) {
    state.status = message;
  }

  function ensurePeer(callback) {
    if (window.Peer) {
      callback();
      return;
    }
    if (peerLoading) {
      peerLoading.push(callback);
      return;
    }
    peerLoading = [callback];
    const script = document.createElement("script");
    script.src = "https://unpkg.com/peerjs@1.5.4/dist/peerjs.min.js";
    script.dataset.slsPeer = "true";
    script.onload = () => {
      const callbacks = peerLoading;
      peerLoading = null;
      callbacks.forEach((done) => done());
    };
    script.onerror = () => {
      peerLoading = null;
      state.busy = false;
      setStatus("Não foi possível carregar o serviço multiplayer.");
    };
    document.head.appendChild(script);
  }

  function send(message) {
    if (connection && connection.open) connection.send(message);
  }

  function dispatchKey(code, down) {
    const canvas = document.querySelector("canvas");
    if (!canvas) return;
    const key = code.startsWith("Key") ? code.slice(3).toLowerCase() : code;
    const event = new KeyboardEvent(down ? "keydown" : "keyup", {
      key, code, bubbles: true, cancelable: true
    });
    canvas.dispatchEvent(event);
    window.dispatchEvent(event);
  }

  function showRemoteVideo(stream) {
    let video = document.getElementById("sls-multiplayer-video");
    if (!video) {
      video = document.createElement("video");
      video.id = "sls-multiplayer-video";
      video.autoplay = true;
      video.playsInline = true;
      video.style.position = "fixed";
      video.style.inset = "0";
      video.style.width = "100vw";
      video.style.height = "100vh";
      video.style.objectFit = "contain";
      video.style.background = "#092b31";
      video.style.zIndex = "10000";
      video.style.pointerEvents = "none";
      document.body.appendChild(video);
    }
    video.srcObject = stream;
    setStatus("Partida em andamento.");
  }

  function startHostStream() {
    if (!state.host || !state.started || streamSent || !connection || !connection.open) return;
    const canvas = document.querySelector("canvas");
    if (!canvas || !canvas.captureStream || !peer) return;
    streamSent = true;
    const call = peer.call(connection.peer, canvas.captureStream(30));
    call.on("error", () => { streamSent = false; });
  }

  function pollHostStream() {
    startHostStream();
    if (state.host) window.setTimeout(pollHostStream, 800);
  }

  function setupConnection(conn, info, isHost) {
    connection = conn;
    conn.on("open", () => {
      if (!isHost) {
        conn.send({ type: "hello", nickname: info.nickname, password: info.password });
        setStatus("Conectando à sala...");
      }
    });
    conn.on("data", (message) => {
      if (!message || typeof message !== "object") return;
      if (isHost && message.type === "hello") {
        if (message.password !== info.password) {
          conn.send({ type: "error", message: "Senha incorreta." });
          window.setTimeout(() => conn.close(), 200);
          return;
        }
        state.connected = true;
        state.guest = message.nickname;
        conn.send({ type: "welcome", nickname: info.nickname });
        setStatus(message.nickname + " entrou na sala. Clique em iniciar partida.");
      } else if (!isHost && message.type === "welcome") {
        state.connected = true;
        setStatus("Conectado com " + message.nickname + ". Aguardando o início.");
      } else if (!isHost && message.type === "start") {
        state.started = true;
        setStatus("Partida iniciando...");
      } else if (!isHost && message.type === "error") {
        state.busy = false;
        setStatus(message.message);
      } else if (isHost && message.type === "key") {
        dispatchKey(message.code, message.down);
      }
    });
    conn.on("close", () => {
      state.connected = false;
      streamSent = false;
      setStatus("A conexão foi encerrada.");
    });
    conn.on("error", () => setStatus("Não foi possível manter a conexão."));
  }

  function setupPeer(info, isHost) {
    state.busy = true;
    state.host = isHost;
    state.connected = false;
    state.started = false;
    state.guest = "";
    const id = isHost ? peerIdFor(info.room) : undefined;
    peer = new window.Peer(id);
    peer.on("open", () => {
      if (isHost) {
        setStatus("Sala criada. Compartilhe nome e senha com seu amigo.");
        pollHostStream();
      } else {
        setupConnection(peer.connect(peerIdFor(info.room), { reliable: true }), info, false);
      }
    });
    peer.on("connection", (conn) => {
      if (isHost && !connection) setupConnection(conn, info, true);
      else conn.close();
    });
    peer.on("call", (call) => {
      if (!isHost) {
        call.answer();
        call.on("stream", showRemoteVideo);
      }
    });
    peer.on("error", (error) => {
      state.busy = false;
      const message = error.type === "unavailable-id" ? "Essa sala já existe." : "Falha na conexão: " + error.type;
      setStatus(message);
    });
  }

  window.slsMultiplayerEnsure = () => ensurePeer(() => {});
  window.slsMultiplayerState = () => JSON.stringify(state);
  window.slsMultiplayerCreate = (nickname, room, password) => ensurePeer(() => setupPeer({ nickname, room, password }, true));
  window.slsMultiplayerJoin = (nickname, room, password) => ensurePeer(() => setupPeer({ nickname, room, password }, false));
  window.slsMultiplayerStart = () => {
    if (!state.host || !state.connected) return;
    state.started = true;
    send({ type: "start" });
    setStatus("Partida iniciando...");
  };
  window.slsMultiplayerLeave = () => {
    if (connection) connection.close();
    if (peer) peer.destroy();
    const video = document.getElementById("sls-multiplayer-video");
    if (video) video.remove();
    peer = null;
    connection = null;
    state.busy = false;
    state.host = false;
    state.connected = false;
    state.started = false;
  };

  document.addEventListener("keydown", (event) => {
    if (state.host || !state.started || !keys.has(event.code)) return;
    event.preventDefault();
    send({ type: "key", code: event.code, down: true });
  });
  document.addEventListener("keyup", (event) => {
    if (state.host || !state.started || !keys.has(event.code)) return;
    event.preventDefault();
    send({ type: "key", code: event.code, down: false });
  });
})();
