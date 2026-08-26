(function (root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory();
  else root.SLSMultiplayerProtocol = factory();
})(typeof globalThis === "undefined" ? this : globalThis, function () {
  "use strict";

  const KEY_CODES = Object.freeze({
    ArrowUp: 38, ArrowDown: 40, ArrowLeft: 37, ArrowRight: 39,
    KeyH: 72, KeyJ: 74, KeyK: 75, KeyL: 76,
    KeyU: 85, KeyI: 73, KeyO: 79
  });

  function teamMessage(state) {
    return {
      type: "teams",
      team1: String(state.team1 || ""),
      team2: String(state.team2 || ""),
      team1_alt: !!state.team1_alt,
      team2_alt: !!state.team2_alt
    };
  }

  function applyTeamsMessage(state, message) {
    if (!message || message.type !== "teams") return false;
    state.team1 = String(message.team1 || "");
    state.team2 = String(message.team2 || "");
    state.team1_alt = !!message.team1_alt;
    state.team2_alt = !!message.team2_alt;
    state.team1_ready = false;
    state.team2_ready = false;
    return true;
  }

  function applyGuestTeamRequest(state, message) {
    if (!state.host || !message || message.type !== "team_request") return false;
    state.team2 = String(message.path || "");
    state.team2_alt = !!message.alt;
    state.team1_ready = false;
    state.team2_ready = false;
    return true;
  }

  function canStartMatch(state) {
    return !!(
      state.host &&
      !state.match_started &&
      state.team1 &&
      state.team2 &&
      state.team1_ready &&
      state.team2_ready
    );
  }

  function keyCodeFor(code) {
    return KEY_CODES[code] || 0;
  }

  function isControlKey(code) {
    return Object.prototype.hasOwnProperty.call(KEY_CODES, code);
  }

  return {teamMessage, applyTeamsMessage, applyGuestTeamRequest, canStartMatch, keyCodeFor, isControlKey};
});
