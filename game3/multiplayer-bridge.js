(function () {
  "use strict";

  const state = {
    status: "Digite seu nickname para começar.",
    busy: false,
    rooms_busy: false,
    rooms: [],
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
  let peerLoadingTimer = null;
  const logs = [];
  const localLogEndpoint = ["localhost", "127.0.0.1", "::1"].includes(window.location.hostname) ? "/__sls_log" : null;
  let debugOutput = null;

  function log(message, details) {
    let line = "[SLS " + new Date().toISOString() + "] " + message;
    if (details !== undefined) {
      try {
        line += " " + (typeof details === "string" ? details : JSON.stringify(details));
      } catch (_error) {
        line += " [detalhes indisponíveis]";
      }
    }
    logs.push(line);
    if (logs.length > 100) logs.shift();
    if (details === undefined) console.info(line);
    else console.info(line, details);
    if (localLogEndpoint && window.fetch) {
      window.fetch(localLogEndpoint, {
        method: "POST",
        headers: {"Content-Type": "text/plain;charset=utf-8"},
        body: line + "\n",
        keepalive: true
      }).catch(() => {});
    }
    if (debugOutput) {
      debugOutput.textContent = logs.join("\n");
      debugOutput.scrollTop = debugOutput.scrollHeight;
    }
  }

  function installDebugPanel() {
    const toggle = document.createElement("button");
    toggle.textContent = "Logs";
    toggle.style.cssText = "position:fixed;right:12px;bottom:12px;z-index:20001;padding:7px 12px;border:1px solid #f5ca70;border-radius:6px;background:#092b31;color:#f5ca70;font:12px sans-serif;cursor:pointer";
    const panel = document.createElement("div");
    panel.style.cssText = "display:none;position:fixed;right:12px;bottom:52px;width:min(720px,calc(100vw - 24px));height:240px;z-index:20000;padding:10px;border:1px solid #f5ca70;border-radius:8px;background:rgba(4,15,22,.96);box-sizing:border-box";
    const copy = document.createElement("button");
    copy.textContent = "Copiar logs";
    copy.style.cssText = "padding:5px 9px;border:1px solid #f5ca70;border-radius:5px;background:#153d4a;color:#fff;font:12px sans-serif;cursor:pointer";
    debugOutput = document.createElement("pre");
    debugOutput.style.cssText = "height:190px;margin:8px 0 0;overflow:auto;white-space:pre-wrap;color:#d8eeee;font:11px monospace";
    copy.onclick = () => navigator.clipboard.writeText(logs.join("\n"));
    toggle.onclick = () => {
      panel.style.display = panel.style.display === "none" ? "block" : "none";
      debugOutput.textContent = logs.join("\n");
    };
    panel.appendChild(copy);
    panel.appendChild(debugOutput);
    document.body.appendChild(panel);
    document.body.appendChild(toggle);
  }

  const roomSlug = (room) => room.trim().toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 24) || "sala";

  const peerIdFor = (room) => {
    let hash = 2166136261;
    for (const char of room.trim().toLowerCase()) {
      hash ^= char.charCodeAt(0);
      hash = Math.imul(hash, 16777619);
    }
    return "sls-" + (hash >>> 0).toString(36) + "-" + roomSlug(room);
  };

  const roomNameFromId = (id) => id.split("-").slice(2).join("-").replace(/-/g, " ") || id;

  function setStatus(message) {
    if (state.status !== message) log("status:", message);
    state.status = message;
  }

  function ensurePeer(callback) {
    if (window.Peer) {
      log("PeerJS já carregado");
      callback();
      return;
    }
    if (peerLoading) {
      log("PeerJS ainda carregando; callback enfileirado");
      peerLoading.push(callback);
      return;
    }
    peerLoading = [callback];
    log("iniciando carregamento do PeerJS");
    const script = document.createElement("script");
    script.src = "https://unpkg.com/peerjs@1.5.4/dist/peerjs.min.js";
    script.dataset.slsPeer = "true";
    peerLoadingTimer = window.setTimeout(() => {
      if (!peerLoading) return;
      peerLoading = null;
      peerLoadingTimer = null;
      state.busy = false;
      state.rooms_busy = false;
      log("timeout carregando PeerJS");
      setStatus("O serviço multiplayer demorou para carregar. Tente novamente.");
    }, 10000);
    script.onload = () => {
      window.clearTimeout(peerLoadingTimer);
      peerLoadingTimer = null;
      const callbacks = peerLoading;
      peerLoading = null;
      log("PeerJS carregado");
      if (callbacks) callbacks.forEach((done) => done());
    };
    script.onerror = () => {
      window.clearTimeout(peerLoadingTimer);
      peerLoadingTimer = null;
      peerLoading = null;
      state.busy = false;
      state.rooms_busy = false;
      log("erro carregando PeerJS", {message: script.src});
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
    log("conexão criada", {peer: conn.peer, host: isHost});
    const timeout = window.setTimeout(() => {
      if (!conn.open) {
        log("timeout aguardando conexão", {peer: conn.peer});
        state.busy = false;
        setStatus("A sala não respondeu. Verifique o nome e tente novamente.");
        conn.close();
      }
    }, 8000);
    conn.on("open", () => {
      window.clearTimeout(timeout);
      log("conexão aberta", {peer: conn.peer, host: isHost});
      if (!isHost) {
        conn.send({ type: "hello", nickname: info.nickname, password: info.password });
        setStatus("Validando a senha da sala...");
      }
    });
    conn.on("data", (message) => {
      if (!message || typeof message !== "object") return;
      log("mensagem recebida", {type: message.type});
      if (isHost && message.type === "hello") {
        if (message.password !== info.password) {
          log("senha incorreta", {peer: conn.peer});
          conn.send({ type: "error", message: "Senha incorreta." });
          window.setTimeout(() => conn.close(), 200);
          return;
        }
        state.busy = false;
        state.connected = true;
        state.guest = message.nickname;
        conn.send({ type: "welcome", nickname: info.nickname });
        setStatus(message.nickname + " entrou na sala. Clique em iniciar partida.");
      } else if (!isHost && message.type === "welcome") {
        state.busy = false;
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
      log("conexão encerrada", {peer: conn.peer});
      state.busy = false;
      state.connected = false;
      streamSent = false;
      setStatus("A conexão foi encerrada.");
    });
    conn.on("error", (error) => {
      window.clearTimeout(timeout);
      log("erro na conexão", {type: error && error.type, message: error && error.message});
      state.busy = false;
      setStatus("Não foi possível conectar à sala.");
    });
  }

  function setupPeer(info, isHost) {
    state.busy = true;
    state.host = isHost;
    state.connected = false;
    state.started = false;
    state.guest = "";
    const id = isHost ? peerIdFor(info.room) : undefined;
    log("abrindo peer", {id: id || "automático", host: isHost});
    try {
      peer = new window.Peer(id);
    } catch (error) {
      log("exceção criando peer", {message: error.message, stack: error.stack});
      state.busy = false;
      state.host = false;
      setStatus("Não foi possível iniciar a conexão multiplayer.");
      return;
    }
    const currentPeer = peer;
    const openTimeout = window.setTimeout(() => {
      if (peer !== currentPeer || currentPeer.open || currentPeer.destroyed) return;
      state.busy = false;
      state.host = false;
      state.connected = false;
      log("timeout abrindo peer", {id: id || "automático"});
      setStatus("A conexão demorou demais. Verifique sua internet e tente novamente.");
      currentPeer.destroy();
    }, 10000);
    peer.on("open", () => {
      window.clearTimeout(openTimeout);
      log("peer aberto", {id: peer.id, host: isHost});
      if (isHost) {
        state.busy = false;
        setStatus("Sala criada. Aguardando seu amigo entrar.");
        pollHostStream();
      } else {
        setupConnection(peer.connect(info.peer_id || peerIdFor(info.room), { reliable: true }), info, false);
      }
    });
    peer.on("connection", (conn) => {
      log("conexão recebida", {peer: conn.peer});
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
      window.clearTimeout(openTimeout);
      log("erro no peer", {type: error && error.type, message: error && error.message});
      state.busy = false;
      state.host = false;
      state.connected = false;
      const message = error.type === "unavailable-id" ? "Essa sala já existe." : "Falha na conexão: " + error.type;
      setStatus(message);
    });
  }

  function listRooms() {
    log("solicitando lista de salas");
    ensurePeer(() => {
      state.rooms_busy = true;
      const browserPeer = new window.Peer();
      browserPeer.on("open", () => {
        browserPeer.listAllPeers((ids) => {
          state.rooms = ids.filter((id) => id.indexOf("sls-") === 0).map((id) => ({ id, name: roomNameFromId(id) }));
          log("salas recebidas", {total: state.rooms.length});
          state.rooms_busy = false;
          setStatus(state.rooms.length ? "Selecione uma sala e digite a senha para entrar." : "Nenhuma sala encontrada.");
          browserPeer.destroy();
        });
      });
      browserPeer.on("error", (error) => {
        log("erro listando salas", {type: error && error.type, message: error && error.message});
        state.rooms_busy = false;
        setStatus("Não foi possível buscar as salas.");
        browserPeer.destroy();
      });
    });
  }

  window.slsMultiplayerEnsure = () => ensurePeer(() => {});
  window.slsMultiplayerState = () => JSON.stringify(state);
  window.slsMultiplayerGetLogs = () => logs.join("\n");
  window.slsMultiplayerListRooms = listRooms;
  window.slsMultiplayerCreate = (nickname, room, password) => {
    log("pedido para criar sala", {nickname, room});
    state.busy = true;
    setStatus("Carregando conexão segura...");
    ensurePeer(() => setupPeer({ nickname, room, password }, true));
  };
  window.slsMultiplayerJoin = (nickname, room, password) => {
    log("pedido para entrar na sala", {nickname, room});
    state.busy = true;
    setStatus("Carregando conexão segura...");
    ensurePeer(() => setupPeer({ nickname, room, password, peer_id: room }, false));
  };
  window.slsMultiplayerStart = () => {
    if (!state.host || !state.connected) return;
    state.started = true;
    send({ type: "start" });
    setStatus("Partida iniciando...");
  };
  window.slsMultiplayerLeave = () => {
    log("saindo da sala");
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

  installDebugPanel();
  log("bridge multiplayer inicializado", {url: window.location.href});
})();
