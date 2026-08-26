// Local usa o servidor do jogo; na publicação, troque pela URL HTTPS da Discloud.
const slsLocal = ["localhost", "127.0.0.1", "::1"].includes(window.location.hostname);
window.SLS_SIGNAL_SERVER = slsLocal ? "/signal" : "";
