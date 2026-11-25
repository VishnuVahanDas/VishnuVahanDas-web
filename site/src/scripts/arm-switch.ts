// Toggles the RC-transmitter contact panel(s).
document.querySelectorAll<HTMLElement>('[data-arm]').forEach((panel) => {
  const btn = panel.querySelector<HTMLButtonElement>('.switch');
  if (!btn) return;
  btn.addEventListener('click', () => {
    const armed = panel.dataset.armed !== 'true';
    panel.dataset.armed = String(armed);
    btn.setAttribute('aria-pressed', String(armed));
    if (armed) panel.querySelector<HTMLAnchorElement>('.links a')?.focus({ preventScroll: true });
  });
});
