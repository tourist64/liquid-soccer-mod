const assert = require("node:assert/strict");
const {spawn} = require("node:child_process");
const net = require("node:net");
const path = require("node:path");
const test = require("node:test");

const SERVER = path.resolve(__dirname, "../multiplayer-server/server.js");

function freePort() {
  return new Promise((resolve, reject) => {
    const probe = net.createServer();
    probe.once("error", reject);
    probe.listen(0, "127.0.0.1", () => {
      const port = probe.address().port;
      probe.close(error => error ? reject(error) : resolve(port));
    });
  });
}

async function waitForHealth(base, process) {
  for (let attempt = 0; attempt < 120; attempt += 1) {
    if (process.exitCode !== null) throw new Error("servidor encerrou antes de ficar disponível");
    try {
      const response = await fetch(`${base}/health`);
      if (response.ok) return;
    } catch (_error) {}
    await new Promise(resolve => setTimeout(resolve, 25));
  }
  throw new Error("servidor não respondeu ao health check");
}

test("fluxo de sala e sinalização funciona com host e convidado", async t => {
  const port = await freePort();
  const base = `http://127.0.0.1:${port}`;
  const room = `test-${Date.now().toString(36)}`;
  const server = spawn(process.execPath, [SERVER], {
    env: {...process.env, PORT: String(port)},
    stdio: ["ignore", "ignore", "pipe"]
  });
  let hostActive = false;
  let guestActive = false;

  async function api(pathname, body) {
    const response = await fetch(base + pathname, body === undefined ? {} : {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify(body)
    });
    const data = await response.json();
    assert.equal(response.ok, true, `${pathname}: ${JSON.stringify(data)}`);
    return data;
  }

  t.after(async () => {
    if (guestActive) await api("/leave", {room, client: "guest"}).catch(() => {});
    if (hostActive) await api("/leave", {room, client: "host"}).catch(() => {});
    server.kill();
  });

  await waitForHealth(base, server);
  assert.deepEqual(await api("/create", {nickname: "Host", room, password: "1234"}), {room, client: "host"});
  hostActive = true;
  assert.equal((await api("/rooms")).rooms.some(item => item.id === room), true);

  assert.deepEqual(await api("/join", {nickname: "Guest", room, password: "1234"}), {room, client: "guest"});
  guestActive = true;
  assert.equal((await api("/rooms")).rooms.some(item => item.id === room), false);
  assert.deepEqual((await api("/poll", {room, client: "host"})).messages, [{type: "join", nickname: "Guest"}]);

  const offer = {type: "offer", description: {type: "offer", sdp: "host"}};
  const answer = {type: "answer", description: {type: "answer", sdp: "guest"}};
  const teams = {type: "teams", team1: "brazil", team2: "france", team1_alt: false, team2_alt: true};
  const teamRequest = {type: "team_request", path: "france", alt: true};
  await api("/send", {room, client: "host", to: "guest", message: offer});
  await api("/send", {room, client: "host", to: "guest", message: teams});
  assert.deepEqual((await api("/poll", {room, client: "guest"})).messages, [offer, teams]);
  await api("/send", {room, client: "guest", to: "host", message: answer});
  await api("/send", {room, client: "guest", to: "host", message: teamRequest});
  assert.deepEqual((await api("/poll", {room, client: "host"})).messages, [answer, teamRequest]);

  await api("/leave", {room, client: "guest"});
  guestActive = false;
  assert.deepEqual((await api("/poll", {room, client: "host"})).messages, [{type: "left"}]);
  await api("/leave", {room, client: "host"});
  hostActive = false;
  assert.equal((await api("/rooms")).rooms.some(item => item.id === room), false);
});
