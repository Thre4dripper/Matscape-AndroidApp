// Small touches for the product page; everything works without it.
(function () {
  // Respect reduced motion: no looping film in the hero.
  var loop = document.querySelector('video.loop');
  var still = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)');
  function motion() {
    if (!loop) return;
    if (still && still.matches) { loop.pause(); loop.removeAttribute('autoplay'); }
    else if (loop.paused) { var p = loop.play(); if (p && p.catch) p.catch(function () {}); }
  }
  motion();
  if (still && still.addEventListener) still.addEventListener('change', motion);

  // Previous / next buttons for the screenshot strip on wide screens.
  var strip = document.querySelector('.gallery');
  var nav = document.querySelector('.gallery-nav');
  if (strip && nav) {
    nav.hidden = false;
    nav.addEventListener('click', function (e) {
      var b = e.target.closest('button');
      if (!b) return;
      var step = strip.querySelector('li').getBoundingClientRect().width + 16;
      strip.scrollBy({ left: step * Number(b.dataset.dir), behavior: 'smooth' });
    });
  }
})();
