// Pan / zoom / reset for <SketchDiagram>, plus a one-time pencil "draw-in".
const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

document.querySelectorAll<HTMLElement>('[data-sketch]').forEach((fig) => {
  const svg = fig.querySelector<SVGSVGElement>('svg')!;
  const home = svg.dataset.home!.split(' ').map(Number);
  let [x, y, w, h] = home;
  const apply = () => svg.setAttribute('viewBox', `${x} ${y} ${w} ${h}`);

  const zoom = (factor: number) => {
    const cx = x + w / 2,
      cy = y + h / 2;
    w = Math.min(home[2] * 2, Math.max(home[2] / 4, w * factor));
    h = w * (home[3] / home[2]);
    x = cx - w / 2;
    y = cy - h / 2;
    apply();
  };

  fig.querySelectorAll<HTMLButtonElement>('[data-zoom]').forEach((b) =>
    b.addEventListener('click', () => {
      if (b.dataset.zoom === 'in') zoom(0.8);
      if (b.dataset.zoom === 'out') zoom(1.25);
      if (b.dataset.zoom === 'reset') {
        [x, y, w, h] = home;
        apply();
      }
    }),
  );

  // Trackpad pinch arrives as ctrl+wheel; plain wheel keeps scrolling the page.
  svg.addEventListener(
    'wheel',
    (e) => {
      if (!e.ctrlKey && !e.metaKey) return;
      e.preventDefault();
      zoom(e.deltaY > 0 ? 1.1 : 0.9);
    },
    { passive: false },
  );

  let drag: { px: number; py: number } | null = null;
  svg.addEventListener('pointerdown', (e) => {
    drag = { px: e.clientX, py: e.clientY };
    svg.setPointerCapture(e.pointerId);
  });
  svg.addEventListener('pointermove', (e) => {
    if (!drag) return;
    const scale = w / svg.clientWidth;
    x -= (e.clientX - drag.px) * scale;
    y -= (e.clientY - drag.py) * scale;
    drag = { px: e.clientX, py: e.clientY };
    apply();
  });
  const end = () => (drag = null);
  svg.addEventListener('pointerup', end);
  svg.addEventListener('pointercancel', end);

  // Draw the pencil strokes in once, the first time the sketch is seen.
  if (reduce || !('IntersectionObserver' in window)) return;
  const strokes = Array.from(svg.querySelectorAll<SVGPathElement>('.strokes path'));
  strokes.forEach((p) => {
    const len = p.getTotalLength();
    p.style.strokeDasharray = `${len}`;
    p.style.strokeDashoffset = `${len}`;
  });
  const io = new IntersectionObserver(
    (entries) => {
      if (!entries.some((en) => en.isIntersecting)) return;
      io.disconnect();
      strokes.forEach((p, i) => {
        p.style.transitionDelay = `${Math.min(i * 25, 900)}ms`;
        p.style.strokeDashoffset = '0';
      });
    },
    { threshold: 0.3 },
  );
  io.observe(svg);
});
