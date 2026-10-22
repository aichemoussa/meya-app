// Builds the "Open in MEYA" button of the invite page from the part of the
// address after "#", which browsers never send to the website. Nothing is
// stored or sent anywhere.
(function () {
  var invite = location.hash.slice(1);
  if (!/^[A-Za-z0-9_-]{20,2048}$/.test(invite)) {
    document.getElementById('no-invite').hidden = false;
    return;
  }
  var open = document.getElementById('open');
  // Android opens meya://invite/<invite> in MEYA.
  open.href = 'intent://invite/' + invite +
    '#Intent;scheme=meya;package=app.meya.messenger;end';
  open.hidden = false;
})();
