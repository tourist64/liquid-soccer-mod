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

test("partida só começa com host, dois times e dois jogadores prontos", () => {
  assert.equal(protocol.canStartMatch(hostState()), false);
  assert.equal(protocol.canStartMatch(hostState({team1_ready: true})), false);
  assert.equal(protocol.canStartMatch(hostState({team1_ready: true, team2_ready: true})), true);
  assert.equal(protocol.canStartMatch(hostState({match_started: true, team1_ready: true, team2_ready: true})), false);
  assert.equal(protocol.canStartMatch(hostState({host: false, team1_ready: true, team2_ready: true})), false);
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

test("mapeia as teclas do segundo jogador para eventos do navegador", () => {
  assert.equal(protocol.keyCodeFor("ArrowUp"), 38);
  assert.equal(protocol.keyCodeFor("KeyJ"), 74);
  assert.equal(protocol.isControlKey("KeyO"), true);
  assert.equal(protocol.keyCodeFor("KeyZ"), 0);
  assert.equal(protocol.isControlKey("KeyZ"), false);
});
