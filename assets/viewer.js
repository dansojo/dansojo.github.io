(() => {
  const get = id => document.getElementById(id);
  const dialog = get('pdf-viewer');
  if (!dialog || typeof dialog.showModal !== 'function') return;
  const title=get('pdf-title'),open=get('pdf-open'),download=get('pdf-download'),close=get('pdf-close');
  const stage=get('pdf-stage'),image=get('pdf-page'),text=get('pdf-text'),count=get('pdf-count'),status=get('pdf-status');
  const prev=get('pdf-prev'),next=get('pdf-next'),zoomIn=get('pdf-zoom-in'),zoomOut=get('pdf-zoom-out'),fit=get('pdf-fit');
  let trigger,manifest,pages=[],index=0,zoom=1,generation=0;
  function setZoom(value) {
    zoom=Math.max(.75,Math.min(3,value));
    image.style.width=`${Math.round(zoom*100)}%`;
    image.style.maxWidth=`${Math.round(zoom*1100)}px`;
    zoomOut.disabled=zoom<=.75;zoomIn.disabled=zoom>=3;
    fit.textContent=zoom===1?'화면 맞춤':`${Math.round(zoom*100)}% · 맞춤`;
  }
  function renderPage(value) {
    if(!pages.length)return;
    index=Math.max(0,Math.min(pages.length-1,value));
    const page=pages[index];
    image.hidden=true;status.textContent='페이지를 불러오는 중입니다…';
    stage.setAttribute('aria-busy','true');
    image.alt=`${title.textContent} · ${index+1} / ${pages.length} 페이지`;
    image.width=page.width;image.height=page.height;image.src=page.src;
    text.textContent=page.text;
    count.textContent=`${index+1} / ${pages.length}`;
    prev.disabled=index===0;next.disabled=index===pages.length-1;
    stage.scrollTo({top:0,left:0});
  }
  image.addEventListener('load',()=>{if(!dialog.open)return;image.hidden=false;stage.setAttribute('aria-busy','false');status.textContent='페이지를 넘기거나 확대해서 읽으실 수 있습니다.';});
  image.addEventListener('error',()=>{if(!dialog.open)return;stage.setAttribute('aria-busy','false');status.textContent='페이지를 불러오지 못했습니다. 새 탭에서 열거나 원본을 다운로드해 주세요.';});
  document.addEventListener('click',async event=>{
    const anchor=event.target.closest('a[data-pdf]');
    if(!anchor||event.button!==0||event.metaKey||event.ctrlKey||event.shiftKey||event.altKey)return;
    const url=new URL(anchor.href,location.href);
    if(url.origin!==new URL(location.href).origin||!url.pathname.endsWith('.pdf'))return;
    event.preventDefault();
    const current=++generation;
    trigger=anchor;title.textContent=anchor.dataset.pdf;open.href=url.href;download.href=url.href;
    download.download=url.pathname.split('/').pop();pages=[];count.textContent='— / —';prev.disabled=next.disabled=true;
    image.hidden=true;text.textContent='';setZoom(1);status.textContent='문서를 불러오는 중입니다…';
    dialog.showModal();document.body.classList.add('viewer-open');close.focus();
    try {
      if(!manifest)manifest=fetch('./assets/document-pages.json?v=20261028').then(response=>{if(!response.ok)throw Error('Manifest unavailable');return response.json();}).catch(error=>{manifest=null;throw error;});
      const documents=await manifest;
      if(current!==generation||!dialog.open)return;
      pages=documents[download.download]?.pages||[];
      if(!pages.length)throw Error('Preview unavailable');
      renderPage(0);
    } catch {
      if(current===generation&&dialog.open)status.textContent='미리보기를 불러오지 못했습니다. 새 탭에서 열거나 원본을 다운로드해 주세요.';
    }
  });
  prev.addEventListener('click',()=>renderPage(index-1));
  next.addEventListener('click',()=>renderPage(index+1));
  zoomIn.addEventListener('click',()=>setZoom(zoom+.25));
  zoomOut.addEventListener('click',()=>setZoom(zoom-.25));
  fit.addEventListener('click',()=>{setZoom(1);stage.scrollTo({top:0,left:0});});
  stage.addEventListener('keydown',event=>{if(zoom>1)return;if(event.key==='ArrowRight'){event.preventDefault();renderPage(index+1);}if(event.key==='ArrowLeft'){event.preventDefault();renderPage(index-1);}});
  close.addEventListener('click',()=>dialog.close());
  dialog.addEventListener('click',event=>{if(event.target===dialog)dialog.close();});
  dialog.addEventListener('close',()=>{generation++;pages=[];image.removeAttribute('src');image.hidden=true;text.textContent='';document.body.classList.remove('viewer-open');trigger?.focus();});
})();
