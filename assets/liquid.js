(() => {
  const canvas = document.getElementById('liquid-canvas');
  if (!canvas) return;
  const gl = canvas.getContext('webgl', {alpha:true, antialias:false, powerPreference:'low-power'});
  if (!gl) return;
  const vertex = 'attribute vec2 a;void main(){gl_Position=vec4(a,0.,1.);}';
  const fragment = `precision mediump float;
  uniform vec2 resolution;uniform float time;
  float shape(vec3 p){
    float t=time*.23;
    float wave=sin(p.x*3.4+t)*sin(p.y*2.8-t*.8)*sin(p.z*3.+t*.6);
    float fold=sin(p.x*5.-p.y*2.+t*.9)*cos(p.z*3.+t);
    return length(p)-.97-wave*.14-fold*.055;
  }
  vec3 normal(vec3 p){vec2 e=vec2(.003,0.);return normalize(vec3(shape(p+e.xyy)-shape(p-e.xyy),shape(p+e.yxy)-shape(p-e.yxy),shape(p+e.yyx)-shape(p-e.yyx)));}
  void main(){
    vec2 uv=(gl_FragCoord.xy-.5*resolution)/min(resolution.x,resolution.y);
    vec3 ro=vec3(0.,0.,3.5);vec3 rd=normalize(vec3(uv*3.2,-3.5));
    float depth=0.;float hit=0.;
    for(int i=0;i<56;i++){float d=shape(ro+rd*depth);if(d<.002){hit=1.;break;}depth+=d*.8;if(depth>6.)break;}
    if(hit<.5){gl_FragColor=vec4(0.);return;}
    vec3 p=ro+rd*depth;vec3 n=normal(p);vec3 view=normalize(ro-p);vec3 reflection=reflect(-view,n);
    float fres=pow(1.-max(dot(n,view),0.),2.8);
    vec3 purple=vec3(.38,.19,.62);vec3 cyan=vec3(.26,.75,.69);vec3 silver=vec3(.85,.76,.98);
    float bands=sin(reflection.y*5.+reflection.x*2.+time*.13)*.5+.5;
    vec3 color=mix(purple,cyan,smoothstep(.38,.95,bands));
    float light=max(dot(n,normalize(vec3(-.6,.9,1.))),0.);
    color*=.12+light*.65;
    float key=pow(max(dot(reflection,normalize(vec3(-.8,1.2,1.))),0.),28.);
    float ribbon=pow(max(0.,1.-abs(reflection.y*.9+reflection.x*.48-.38)),35.);
    color+=silver*key*.95+mix(silver,cyan,bands)*ribbon*.6;
    color+=mix(purple,cyan,smoothstep(-.6,.8,n.y))*fres*.7;
    color=pow(color,vec3(.86));
    gl_FragColor=vec4(color,1.);
  }`;
  function compile(type, source) {
    const shader=gl.createShader(type);gl.shaderSource(shader,source);gl.compileShader(shader);
    if (!gl.getShaderParameter(shader,gl.COMPILE_STATUS)) {gl.deleteShader(shader);return null;}
    return shader;
  }
  const vs=compile(gl.VERTEX_SHADER,vertex),fs=compile(gl.FRAGMENT_SHADER,fragment);
  if(!vs||!fs)return;
  const program=gl.createProgram();gl.attachShader(program,vs);gl.attachShader(program,fs);gl.linkProgram(program);
  if(!gl.getProgramParameter(program,gl.LINK_STATUS))return;
  gl.useProgram(program);const buffer=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,buffer);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([-1,-1,1,-1,-1,1,-1,1,1,-1,1,1]),gl.STATIC_DRAW);
  const attr=gl.getAttribLocation(program,'a');gl.enableVertexAttribArray(attr);gl.vertexAttribPointer(attr,2,gl.FLOAT,false,0,0);
  const res=gl.getUniformLocation(program,'resolution'),clock=gl.getUniformLocation(program,'time');
  const toggle=document.getElementById('motion-toggle');
  const reduced=matchMedia('(prefers-reduced-motion: reduce)');
  let visible=true,request=0,last=0,start=performance.now(),lost=false,userPaused=false;
  function draw(now){
    request=0;
    if(lost||document.hidden||!visible||userPaused)return;
    if(now-last>32||reduced.matches){
      const size=Math.min(760,Math.round(canvas.clientWidth*Math.min(devicePixelRatio||1,1.5)));
      if(canvas.width!==size||canvas.height!==size){canvas.width=size;canvas.height=size;gl.viewport(0,0,size,size);}
      gl.uniform2f(res,size,size);gl.uniform1f(clock,reduced.matches?2.4:(now-start)/1000);gl.drawArrays(gl.TRIANGLES,0,6);canvas.classList.add('ready');last=now;
    }
    if(!reduced.matches&&!userPaused)request=requestAnimationFrame(draw);
  }
  function resume(){if(!request&&!document.hidden&&visible&&!lost&&!userPaused)request=requestAnimationFrame(draw);}
  function pause(){cancelAnimationFrame(request);request=0;}
  if('IntersectionObserver' in window)new IntersectionObserver(entries=>{visible=entries[0].isIntersecting;visible?resume():pause();}).observe(canvas);
  document.addEventListener('visibilitychange',()=>document.hidden?pause():resume());
  function updateToggle(){
    if(!toggle)return;
    toggle.hidden=reduced.matches||lost;
    toggle.textContent=userPaused?'모션 재생':'모션 일시정지';
  }
  toggle?.addEventListener('click',()=>{userPaused=!userPaused;userPaused?pause():resume();updateToggle();});
  reduced.addEventListener('change',()=>{pause();updateToggle();resume();});
  window.addEventListener('resize',resume);
  canvas.addEventListener('webglcontextlost',event=>{event.preventDefault();lost=true;pause();canvas.classList.remove('ready');updateToggle();});
  updateToggle();
  resume();
})();
