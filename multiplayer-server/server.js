const http = require("node:http");
const { URL } = require("node:url");

const port = Number(process.env.PORT || 8080);
const rooms = new Map();
const maxAge = 10 * 60 * 1000;

function json(res, status, body) {
  const data = JSON.stringify(body);
  res.writeHead(status, {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": Buffer.byteLength(data)
  });
  res.end(data);
}

function clean(value, fallback) {
  return String(value || fallback || "").trim().slice(0, 40);
}

function roomKey(value) {
  return clean(value).toLowerCase().replace(/[^a-z0-9_-]+/g, "-").replace(/^-|-$/g, "").slice(0, 32);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let body = "";
    req.on("data", chunk => { body += chunk; if (body.length > 100000) reject(new Error("payload grande")); });
    req.on("end", () => {
      try { resolve(body ? JSON.parse(body) : {}); } catch (_error) { reject(new Error("JSON inválido")); }
    });
    req.on("error", reject);
  });
}

function getRoom(body) {
  const room = rooms.get(roomKey(body.room));
  if (!room) throw new Error("Sala não encontrada.");
  if (body.client !== "host" && body.client !== "guest") throw new Error("Cliente inválido.");
  room.lastActivity = Date.now();
  return room;
}

function enqueue(room, client, message) {
  room.queues[client].push(message);
  room.queues[client] = room.queues[client].slice(-100);
}

async function handle(req, res) {
  const url = new URL(req.url, "http://localhost");
  if (req.method === "OPTIONS") return json(res, 204, {});
  if (req.method === "GET" && url.pathname === "/health") return json(res, 200, {ok: true});
  if (req.method === "GET" && url.pathname === "/rooms") {
    const available = [...rooms.entries()]
      .filter(([, room]) => !room.guest)
      .map(([id, room]) => ({id, name: room.name, players: 1}));
    return json(res, 200, {rooms: available});
  }
  if (req.method !== "POST") return json(res, 404, {error: "Rota não encontrada."});

  const body = await readBody(req);
  if (url.pathname === "/create") {
    const key = roomKey(body.room);
    if (!key || !body.password || !body.nickname) throw new Error("Preencha nickname, sala e senha.");
    if (rooms.has(key)) throw new Error("Sala já existe.");
    rooms.set(key, {
      name: clean(body.room), password: String(body.password), host: {nickname: clean(body.nickname)}, guest: null,
      queues: {host: [], guest: []}, lastActivity: Date.now()
    });
    return json(res, 200, {room: key, client: "host"});
  }
  if (url.pathname === "/join") {
    const room = rooms.get(roomKey(body.room));
    if (!room) throw new Error("Sala não encontrada.");
    if (room.password !== String(body.password || "")) throw new Error("Senha incorreta.");
    if (room.guest) throw new Error("A sala já está cheia.");
    room.guest = {nickname: clean(body.nickname)};
    room.lastActivity = Date.now();
    enqueue(room, "host", {type: "join", nickname: room.guest.nickname});
    return json(res, 200, {room: roomKey(body.room), client: "guest"});
  }
  const room = getRoom(body);
  if (url.pathname === "/poll") {
    const messages = room.queues[body.client];
    room.queues[body.client] = [];
    return json(res, 200, {messages});
  }
  if (url.pathname === "/send") {
    if (body.to !== "host" && body.to !== "guest") throw new Error("Destinatário inválido.");
    enqueue(room, body.to, body.message || {});
    return json(res, 200, {ok: true});
  }
  if (url.pathname === "/leave") {
    if (room.guest && body.client === "guest") enqueue(room, "host", {type: "left"});
    if (body.client === "host" || !room.guest) rooms.delete(roomKey(body.room));
    else room.guest = null;
    return json(res, 200, {ok: true});
  }
  return json(res, 404, {error: "Rota não encontrada."});
}

setInterval(() => {
  const cutoff = Date.now() - maxAge;
  for (const [key, room] of rooms) if (room.lastActivity < cutoff) rooms.delete(key);
}, 60 * 1000).unref();

const server = http.createServer((req, res) => {
  handle(req, res).catch(error => json(res, 400, {error: error.message}));
});
server.listen(port, "0.0.0.0", () => console.log(`Sinalização HTTP na porta ${port}`));
