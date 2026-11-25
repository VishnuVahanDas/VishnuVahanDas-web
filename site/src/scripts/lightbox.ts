// Opens [data-lightbox] links in the shared <dialog class="lb">.
const dialog = document.querySelector<HTMLDialogElement>('dialog.lb');
if (dialog) {
  const img = dialog.querySelector('img')!;
  const cap = dialog.querySelector('.cap')!;
  document.addEventListener('click', (e) => {
    const link = (e.target as HTMLElement).closest<HTMLAnchorElement>('a[data-lightbox]');
    if (!link) return;
    e.preventDefault();
    const inner = link.querySelector('img');
    img.src = link.href;
    img.alt = inner?.alt ?? '';
    cap.textContent = link.dataset.caption ?? '';
    dialog.showModal();
  });
  dialog.addEventListener('click', (e) => {
    if (e.target === dialog) dialog.close();
  });
}
