const test = require("node:test");
const assert = require("node:assert/strict");
const protocol = require("../game3/multiplayer-protocol.js");

function hostState(overrides = {}) {
  return Object.assign({
    host: true,
    match_started: false,
    team1: "res://Teams/3/Brazil.tres",
    team2: "res://Teams/3/France.tres",
    team1_alt: false,
    team2_alt: true,
    team1_ready: false,
    team2_ready: false
  }, overrides);
}

test("cria um snapshot atômico dos dois times", () => {
  const message = protocol.teamMessage(hostState());
  assert.deepEqual(message, {
    type: "teams",
    team1: "res://Teams/3/Brazil.tres",
    team2: "res://Teams/3/France.tres",
    team1_alt: false,
    team2_alt: true
  });
});

test("convidado não pode alterar a seleção autoritativa", () => {
  const state = hostState({host: false, team2: "old"});
  assert.equal(protocol.applyGuestTeamRequest(state, {type: "team_request", path: "new"}), false);
  assert.equal(state.team2, "old");
});

test("host aceita o time do convidado e limpa confirmações", () => {
  const state = hostState({team1_ready: true, team2_ready: true});
  assert.equal(protocol.applyGuestTeamRequest(state, {type: "team_request", path: "guest-team", alt: true}), true);
  assert.equal(state.team2, "guest-team");
  assert.equal(state.team2_alt, true);
  assert.equal(state.team1_ready, false);
  assert.equal(state.team2_ready, false);
});

test("host pode iniciar assim que os dois times estiverem definidos", () => {
  assert.equal(protocol.canStartMatch(hostState()), false);
  assert.equal(protocol.canStartMatch(hostState({team1_ready: true})), false);
  assert.equal(protocol.canStartMatch(hostState({started: true, team1_ready: true})), true);
  assert.equal(protocol.canStartMatch(hostState({started: true, match_started: true, team1_ready: true})), false);
  assert.equal(protocol.canStartMatch(hostState({started: true, host: false, team1_ready: true})), false);
});

test("seleção do convidado substitui a prévia e chega igual aos dois lados", () => {
  const host = hostState({started: true, team1_ready: true, team2_ready: true});
  const guest = hostState({host: false, started: true, team1: "local-home", team2: "local-away"});
  assert.equal(protocol.applyGuestTeamRequest(host, {type: "team_request", path: "guest-team", alt: true}), true);
  assert.equal(protocol.applyTeamsMessage(guest, protocol.teamMessage(host)), true);
  assert.deepEqual({team1: guest.team1, team2: guest.team2, team1_alt: guest.team1_alt, team2_alt: guest.team2_alt}, {
    team1: host.team1, team2: "guest-team", team1_alt: host.team1_alt, team2_alt: true
  });
  assert.equal(host.team1_ready, false);
  assert.equal(host.team2_ready, false);
  assert.equal(guest.team1_ready, false);
  assert.equal(guest.team2_ready, false);
});

test("convidado mantém sua prévia enquanto o host confirma a seleção", () => {
  const guest = hostState({host: false, started: true, team2: "old-team", team2_alt: false, team1_ready: true, team2_ready: true});
  assert.equal(protocol.applyGuestTeamPreview(guest, "new-team", true), true);
  assert.equal(guest.team2, "new-team");
  assert.equal(guest.team2_alt, true);
  assert.equal(guest.team1_ready, false);
  assert.equal(guest.team2_ready, false);
});

test("convidado aplica o snapshot do host nos dois lados", () => {
  const state = {team1: "local-1", team2: "local-2", team1_alt: false, team2_alt: false, team1_ready: true, team2_ready: true};
  assert.equal(protocol.applyTeamsMessage(state, {
    type: "teams", team1: "host-1", team2: "host-2", team1_alt: true, team2_alt: false
  }), true);
  assert.deepEqual(state, {
    team1: "host-1", team2: "host-2", team1_alt: true, team2_alt: false,
    team1_ready: false, team2_ready: false
  });
});

test("snapshot da partida só é aplicado pelo convidado", () => {
  const host = hostState({host: true});
  const guest = hostState({host: false});
  const snapshot = {ball: [1, 2, 3], score: [2, 1], players: [[4, 0, 5]]};
  const message = protocol.gameStateMessage(snapshot);
  assert.equal(protocol.applyGameStateMessage(host, message), false);
  assert.equal(protocol.applyGameStateMessage(guest, message), true);
  assert.deepEqual(guest.remote_game_state, snapshot);
  assert.equal(guest.remote_game_state_version, 1);
});

test("ignora snapshots de partida inválidos", () => {
  const guest = hostState({host: false});
  assert.equal(protocol.applyGameStateMessage(guest, {type: "game_state"}), false);
  assert.equal(protocol.applyGameStateMessage(guest, {type: "teams", snapshot: {}}), false);
});

test("mapeia as teclas do segundo jogador para eventos do navegador", () => {
  assert.equal(protocol.keyCodeFor("ArrowUp"), 38);
  assert.equal(protocol.keyCodeFor("KeyJ"), 74);
  assert.equal(protocol.isControlKey("KeyO"), true);
  assert.equal(protocol.keyCodeFor("KeyZ"), 0);
  assert.equal(protocol.isControlKey("KeyZ"), false);
});

test("fila de controles preserva tecla e estado", () => {
  assert.deepEqual(protocol.controlMessage("KeyJ", true), {type: "key", code: "KeyJ", down: true});
  assert.deepEqual(protocol.controlMessage("ArrowLeft", false), {type: "key", code: "ArrowLeft", down: false});
});
