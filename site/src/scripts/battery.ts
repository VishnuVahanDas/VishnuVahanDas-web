// Drains the LiPo as the reader scrolls: 12.6 V (top) → 10.5 V (bottom).
const pack = document.querySelector<HTMLElement>('[data-battery]');
if (pack) {
  const cells = pack.querySelectorAll<HTMLElement>('.cell');
  const volts = pack.querySelector<HTMLElement>('[data-volts]')!;
  let ticking = false;

  const update = () => {
    ticking = false;
    const max = document.documentElement.scrollHeight - window.innerHeight;
    const p = max > 0 ? Math.min(1, Math.max(0, window.scrollY / max)) : 0;
    const v = 12.6 - p * 2.1;
    const lit = Math.ceil((1 - p) * cells.length - 0.001);
    cells.forEach((c, i) => c.classList.toggle('off', i >= lit));
    const landNow = p > 0.97;
    volts.textContent = landNow ? 'LAND NOW · 10.5V' : `3S · ${v.toFixed(1)}V`;
    volts.classList.toggle('low', v < 11.1);
    if (window.scrollY > 40) pack.classList.add('scrolled');
  };

  window.addEventListener(
    'scroll',
    () => {
      if (!ticking) {
        ticking = true;
        requestAnimationFrame(update);
      }
    },
    { passive: true },
  );
  update();
}
