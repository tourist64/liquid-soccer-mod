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
    match_started: false,
    guest: "",
    team1: "",
    team2: "",
    team1_alt: false,
    team2_alt: false,
    team1_ready: false,
    team2_ready: false
  };
  const keys = new Set([
    "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight",
    "KeyH", "KeyJ", "KeyK", "KeyL", "KeyU", "KeyI", "KeyO"
  ]);
  const logs = [];
  const localLogEndpoint = ["localhost", "127.0.0.1", "::1"].includes(window.location.hostname) ? "/__sls_log" : null;
  const signalServer = window.SLS_SIGNAL_SERVER || null;
  const signalServerUrl = typeof signalServer === "string" ? signalServer.replace(/\/$/, "") : signalServer && signalServer.url;
  let debugOutput = null;
  let roomSession = null;
  let pollTimer = null;
  let rtc = null;
  let dataChannel = null;
  let pendingCandidates = [];
  let localVideoTracks = [];
  let remoteStream = null;

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

  function setStatus(message) {
    if (state.status !== message) log("status:", message);
    state.status = message;
  }

  async function signalRequest(path, payload, method) {
    if (!signalServerUrl) throw new Error("Servidor de sinalização não configurado");
    const options = {method: method || (payload === undefined ? "GET" : "POST"), headers: {}};
    if (payload !== undefined) {
      options.headers["Content-Type"] = "application/json";
      options.body = JSON.stringify(payload);
    }
    const response = await window.fetch(signalServerUrl + path, options);
    const text = await response.text();
    let data = {};
    try { data = text ? JSON.parse(text) : {}; } catch (_error) { data = {error: text}; }
    if (!response.ok) throw new Error(data.error || ("HTTP " + response.status));
    return data;
  }

  function roomData() {
    return {room: roomSession.room, client: roomSession.client};
  }

  async function sendSignal(message, to) {
    if (!roomSession) return;
    await signalRequest("/send", Object.assign(roomData(), {to, message}));
  }

  function stopPolling() {
    if (pollTimer) window.clearTimeout(pollTimer);
    pollTimer = null;
  }

  function startPolling() {
    stopPolling();
    const poll = async () => {
      if (!roomSession) return;
      try {
        const result = await signalRequest("/poll", roomData());
        for (const message of result.messages || []) await handleSignal(message);
      } catch (error) {
        log("erro no polling", {message: error.message});
        if (roomSession) setStatus("O servidor multiplayer não respondeu.");
      }
      if (roomSession) pollTimer = window.setTimeout(poll, 300);
    };
    poll();
  }

  function dispatchKey(code, down) {
    const canvas = document.querySelector("canvas");
    if (!canvas) return;
    const key = code.startsWith("Key") ? code.slice(3).toLowerCase() : code;
    const event = new KeyboardEvent(down ? "keydown" : "keyup", {key, code, bubbles: true, cancelable: true});
    canvas.dispatchEvent(event);
    window.dispatchEvent(event);
  }

  function showRemoteVideo(stream) {
    remoteStream = stream;
    if (!state.match_started) return;
    let video = document.getElementById("sls-multiplayer-video");
    if (!video) {
      video = document.createElement("video");
      video.id = "sls-multiplayer-video";
      video.autoplay = true;
      video.playsInline = true;
      video.style.cssText = "display:none;position:fixed;inset:0;width:100vw;height:100vh;object-fit:contain;background:#092b31;z-index:10000;pointer-events:none";
      video.onplaying = () => { video.style.display = "block"; };
      document.body.appendChild(video);
    }
    video.srcObject = stream;
    video.play().catch(() => {});
    setStatus("Partida em andamento.");
  }

  function bindDataChannel(channel, isHost) {
    dataChannel = channel;
    channel.onopen = () => {
      log("canal de controle aberto", {host: isHost});
      state.connected = true;
      state.busy = false;
      setStatus(isHost ? state.guest + " conectado. Clique em iniciar partida." : "Conectado. Aguardando o início.");
    };
    channel.onmessage = (event) => {
      let message;
      try { message = JSON.parse(event.data); } catch (_error) { return; }
      if (isHost && message.type === "key") dispatchKey(message.code, message.down);
      if (!isHost && message.type === "start") {
        state.started = true;
        setStatus("Partida iniciando...");
      }
      if (message.type === "team") {
        const side = message.side === "team1" ? "team1" : "team2";
        if (side !== (state.host ? "team1" : "team2")) {
          state[side] = String(message.path || "");
          state[side + "_alt"] = !!message.alt;
          state[side + "_ready"] = false;
        }
      }
      if (message.type === "ready") {
        const side = message.side === "team1" ? "team1" : "team2";
        if (side !== (state.host ? "team1" : "team2")) state[side + "_ready"] = true;
        maybeStartMatch();
      }
      if (message.type === "match_start") {
        state.match_started = true;
        showRemoteVideo(remoteStream);
        setStatus("Partida em andamento.");
      }
    };
    channel.onclose = () => {
      dataChannel = null;
      state.connected = false;
      state.started = false;
      setStatus("A conexão foi encerrada.");
    };
  }

  async function addCandidate(candidate) {
    if (!rtc) return;
    if (!rtc.remoteDescription) {
      pendingCandidates.push(candidate);
      return;
    }
    try { await rtc.addIceCandidate(candidate); } catch (error) { log("erro adicionando candidato ICE", {message: error.message}); }
  }

  async function flushCandidates() {
    const candidates = pendingCandidates;
    pendingCandidates = [];
    for (const candidate of candidates) await addCandidate(candidate);
  }

  function createRtc(isHost) {
    if (!window.RTCPeerConnection) throw new Error("WebRTC não disponível neste navegador");
    rtc = new RTCPeerConnection({iceServers: [{urls: "stun:stun.l.google.com:19302"}]});
    rtc.onicecandidate = (event) => {
      if (event.candidate) sendSignal({type: "candidate", candidate: event.candidate}, isHost ? "guest" : "host").catch((error) => log("erro enviando ICE", {message: error.message}));
    };
    rtc.onconnectionstatechange = () => {
      log("estado WebRTC", {state: rtc.connectionState});
      if (rtc.connectionState === "failed" || rtc.connectionState === "closed") {
        state.connected = false;
        setStatus("A conexão WebRTC falhou.");
      }
    };
    rtc.ontrack = (event) => showRemoteVideo(event.streams[0]);
    if (isHost) {
      const canvas = document.querySelector("canvas");
      if (canvas && canvas.captureStream) {
        localVideoTracks = canvas.captureStream(15).getVideoTracks();
        for (const track of localVideoTracks) {
          track.enabled = false;
          track.contentHint = "motion";
          const sender = rtc.addTrack(track);
          const parameters = sender.getParameters();
          parameters.encodings = parameters.encodings || [{}];
          parameters.encodings[0].maxBitrate = 700000;
          parameters.encodings[0].maxFramerate = 15;
          parameters.encodings[0].scaleResolutionDownBy = 1.5;
          sender.setParameters(parameters).catch(() => {});
        }
      }
      bindDataChannel(rtc.createDataChannel("controls"), true);
    } else {
      rtc.ondatachannel = (event) => bindDataChannel(event.channel, false);
    }
  }

  async function createOffer() {
    try {
      createRtc(true);
      const offer = await rtc.createOffer();
      await rtc.setLocalDescription(offer);
      await sendSignal({type: "offer", description: rtc.localDescription}, "guest");
      setStatus("Conectando com seu amigo...");
    } catch (error) {
      log("erro criando oferta", {message: error.message, stack: error.stack});
      setStatus("Não foi possível preparar a partida.");
    }
  }

  function maybeStartMatch() {
    if (!state.host || state.match_started || !state.team1_ready || !state.team2_ready) return;
    state.match_started = true;
    localVideoTracks.forEach((track) => { track.enabled = true; });
    if (dataChannel && dataChannel.readyState === "open") dataChannel.send(JSON.stringify({type: "match_start"}));
    setStatus("Partida em andamento.");
  }

  async function handleSignal(message) {
    log("mensagem de sinalização", {type: message.type});
    if (message.type === "join" && state.host) {
      state.guest = message.nickname;
      await createOffer();
    } else if (message.type === "offer" && !state.host) {
      try {
        createRtc(false);
        await rtc.setRemoteDescription(message.description);
        await flushCandidates();
        const answer = await rtc.createAnswer();
        await rtc.setLocalDescription(answer);
        await sendSignal({type: "answer", description: rtc.localDescription}, "host");
      } catch (error) {
        log("erro respondendo oferta", {message: error.message, stack: error.stack});
        setStatus("Não foi possível entrar na partida.");
      }
    } else if (message.type === "answer" && state.host && rtc) {
      try {
        await rtc.setRemoteDescription(message.description);
        await flushCandidates();
      } catch (error) { log("erro aceitando resposta", {message: error.message}); }
    } else if (message.type === "candidate") {
      await addCandidate(message.candidate);
    } else if (message.type === "left") {
      state.connected = false;
      state.started = false;
      setStatus("O outro jogador saiu da sala.");
    }
  }

  async function listRooms() {
    log("solicitando lista de salas");
    state.rooms_busy = true;
    try {
      const result = await signalRequest("/rooms");
      state.rooms = (result.rooms || []).map(room => Object.assign({id: room.name}, room));
      setStatus(state.rooms.length ? "Selecione uma sala e digite a senha para entrar." : "Nenhuma sala encontrada.");
      log("salas recebidas", {total: state.rooms.length});
    } catch (error) {
      log("erro listando salas", {message: error.message});
      setStatus("Não foi possível buscar as salas.");
    } finally {
      state.rooms_busy = false;
    }
  }

  async function createRoom(nickname, room, password) {
    log("pedido para criar sala", {nickname, room});
    state.busy = true;
    setStatus("Criando sala...");
    try {
      const result = await signalRequest("/create", {nickname, room, password});
      roomSession = {room: result.room, client: result.client};
      state.host = true;
      state.busy = false;
      setStatus("Sala criada. Aguardando seu amigo entrar.");
      startPolling();
    } catch (error) {
      log("erro criando sala", {message: error.message});
      state.busy = false;
      setStatus(error.message === "Sala já existe." ? error.message : "Não foi possível criar a sala.");
    }
  }

  async function joinRoom(nickname, room, password) {
    log("pedido para entrar na sala", {nickname, room});
    state.busy = true;
    setStatus("Entrando na sala...");
    try {
      const result = await signalRequest("/join", {nickname, room, password});
      roomSession = {room: result.room, client: result.client};
      state.host = false;
      state.busy = false;
      setStatus("Sala encontrada. Negociando conexão...");
      startPolling();
    } catch (error) {
      log("erro entrando na sala", {message: error.message});
      state.busy = false;
      setStatus(error.message || "Não foi possível entrar na sala.");
    }
  }

  window.slsMultiplayerEnsure = () => {
    if (!signalServerUrl) setStatus("Servidor multiplayer não configurado.");
  };
  window.slsMultiplayerState = () => JSON.stringify(state);
  window.slsMultiplayerGetLogs = () => logs.join("\n");
  window.slsMultiplayerListRooms = listRooms;
  window.slsMultiplayerCreate = createRoom;
  window.slsMultiplayerJoin = joinRoom;
  window.slsMultiplayerSetTeam = (path, alt) => {
    if (!dataChannel || dataChannel.readyState !== "open") return;
    const side = state.host ? "team1" : "team2";
    state[side] = String(path || "");
    state[side + "_alt"] = !!alt;
    state[side + "_ready"] = false;
    dataChannel.send(JSON.stringify({type: "team", side, path: state[side], alt: state[side + "_alt"]}));
  };
  window.slsMultiplayerReady = () => {
    if (!dataChannel || dataChannel.readyState !== "open") return;
    const side = state.host ? "team1" : "team2";
    state[side + "_ready"] = true;
    dataChannel.send(JSON.stringify({type: "ready", side}));
    maybeStartMatch();
  };
  window.slsMultiplayerStart = () => {
    if (!state.host || !state.connected || !dataChannel || dataChannel.readyState !== "open") return;
    state.started = true;
    state.match_started = false;
    state.team1 = "";
    state.team2 = "";
    state.team1_alt = false;
    state.team2_alt = false;
    state.team1_ready = false;
    state.team2_ready = false;
    dataChannel.send(JSON.stringify({type: "start"}));
    setStatus("Partida iniciando...");
  };
  window.slsMultiplayerLeave = () => {
    log("saindo da sala");
    if (roomSession) signalRequest("/leave", roomData()).catch(() => {});
    stopPolling();
    if (dataChannel) dataChannel.close();
    if (rtc) rtc.close();
    localVideoTracks.forEach((track) => track.stop());
    const video = document.getElementById("sls-multiplayer-video");
    if (video) video.remove();
    roomSession = null;
    rtc = null;
    dataChannel = null;
    pendingCandidates = [];
    localVideoTracks = [];
    remoteStream = null;
    state.busy = false;
    state.host = false;
    state.connected = false;
    state.started = false;
    state.match_started = false;
    state.guest = "";
    state.team1 = "";
    state.team2 = "";
    state.team1_alt = false;
    state.team2_alt = false;
    state.team1_ready = false;
    state.team2_ready = false;
  };

  document.addEventListener("keydown", (event) => {
    if (state.host || !state.started || !keys.has(event.code)) return;
    event.preventDefault();
    if (dataChannel && dataChannel.readyState === "open") dataChannel.send(JSON.stringify({type: "key", code: event.code, down: true}));
  });
  document.addEventListener("keyup", (event) => {
    if (state.host || !state.started || !keys.has(event.code)) return;
    event.preventDefault();
    if (dataChannel && dataChannel.readyState === "open") dataChannel.send(JSON.stringify({type: "key", code: event.code, down: false}));
  });

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", installDebugPanel);
  else installDebugPanel();
  log("bridge multiplayer inicializado", {url: window.location.href, signal_server: signalServerUrl || "não configurado"});
})();
