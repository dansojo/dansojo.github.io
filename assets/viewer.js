(() => {
  const dialog = document.getElementById('pdf-viewer');
  if (!dialog || typeof dialog.showModal !== 'function') return;
  const frame = document.getElementById('pdf-frame');
  const title = document.getElementById('pdf-title');
  const open = document.getElementById('pdf-open');
  const download = document.getElementById('pdf-download');
  const close = document.getElementById('pdf-close');
  let trigger;
  document.addEventListener('click', event => {
    const anchor = event.target.closest('a[data-pdf]');
    if (!anchor || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    const url = new URL(anchor.href, location.href);
    if (url.origin !== new URL(location.href).origin || !url.pathname.endsWith('.pdf')) return;
    event.preventDefault();
    trigger = anchor;
    title.textContent = anchor.dataset.pdf;
    open.href = url.href;
    download.href = url.href;
    download.download = url.pathname.split('/').pop();
    frame.src = url.href + '#view=FitH';
    frame.title = anchor.dataset.pdf + ' PDF 미리보기';
    dialog.showModal();
    document.body.classList.add('viewer-open');
    close.focus();
  });
  close.addEventListener('click', () => dialog.close());
  dialog.addEventListener('click', event => {
    if (event.target === dialog) dialog.close();
  });
  dialog.addEventListener('close', () => {
    frame.removeAttribute('src');
    document.body.classList.remove('viewer-open');
    trigger?.focus();
  });
})();
