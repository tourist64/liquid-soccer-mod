// Local usa um servidor próprio; a publicação continua apontando para o cloud.
const slsLocal = ["localhost", "127.0.0.1", "::1"].includes(window.location.hostname);
window.SLS_PEER_SERVER = slsLocal ? {
  host: "127.0.0.1", port: 9000, secure: false, path: "/peerjs", key: "peerjs"
} : {
  host: "1.peerjs.com", port: 443, secure: true, path: "/", key: "peerjs"
};
