const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const source=fs.readFileSync('assets/liquid.js','utf8');
function setup(reduced=false,available=true){
 const callbacks=new Map(),events={},canvasEvents={},classes=new Set();let id=0,draws=0,observer;
 const gl={VERTEX_SHADER:1,FRAGMENT_SHADER:2,COMPILE_STATUS:3,LINK_STATUS:4,ARRAY_BUFFER:5,STATIC_DRAW:6,FLOAT:7,TRIANGLES:8};
 for(const k of ['shaderSource','compileShader','deleteShader','attachShader','linkProgram','useProgram','bindBuffer','bufferData','enableVertexAttribArray','vertexAttribPointer','viewport','uniform2f','uniform1f'])gl[k]=()=>{};
 for(const k of ['createShader','createProgram','createBuffer','getUniformLocation'])gl[k]=()=>({});
 gl.getShaderParameter=gl.getProgramParameter=()=>true;gl.getAttribLocation=()=>0;gl.drawArrays=()=>draws++;
 const canvas={width:0,height:0,clientWidth:400,getContext:()=>available?gl:null,classList:{add:x=>classes.add(x),remove:x=>classes.delete(x)},addEventListener:(k,f)=>canvasEvents[k]=f};
 const toggle={hidden:true,textContent:"",handlers:{},addEventListener(k,f){this.handlers[k]=f;}};
 const preference={matches:reduced,addEventListener:(k,f)=>events.preference=f};
 const document={hidden:false,getElementById:id=>id==="motion-toggle"?toggle:canvas,addEventListener:(k,f)=>events[k]=f};
 const window={IntersectionObserver:true,addEventListener:(k,f)=>events[k]=f};
 vm.runInNewContext(source,{document,window,matchMedia:()=>preference,performance:{now:()=>0},devicePixelRatio:2,Float32Array,Math,IntersectionObserver:class{constructor(fn){observer=fn}observe(){}},requestAnimationFrame:f=>{callbacks.set(++id,f);return id},cancelAnimationFrame:i=>callbacks.delete(i)});
 function tick(t=100){const current=[...callbacks.values()];callbacks.clear();current.forEach(f=>f(t));}
 return {toggle,callbacks,events,document,preference,canvas,classes,canvasEvents,tick,get draws(){return draws},visibility:v=>observer([{isIntersecting:v}])};
}
let s=setup(true);s.tick();assert.equal(s.draws,1);assert.equal(s.callbacks.size,0);assert.equal(s.canvas.width,600);assert(s.classes.has('ready'));
s=setup();s.tick();assert.equal(s.callbacks.size,1);s.visibility(false);assert.equal(s.callbacks.size,0);s.visibility(true);assert.equal(s.callbacks.size,1);s.document.hidden=true;s.events.visibilitychange();assert.equal(s.callbacks.size,0);s.document.hidden=false;s.events.visibilitychange();s.tick(200);assert.equal(s.callbacks.size,1);s.preference.matches=true;s.events.preference();s.tick(300);assert.equal(s.callbacks.size,0);s.canvasEvents.webglcontextlost({preventDefault(){}});assert(!s.classes.has('ready'));assert.equal(s.callbacks.size,0);
s=setup(false,false);assert.equal(s.callbacks.size,0);assert.equal(s.classes.size,0);
s=setup();s.tick();assert.equal(typeof s.toggle.handlers.click,'function');assert.equal(s.toggle.hidden,false);s.toggle.handlers.click();assert.equal(s.callbacks.size,0);assert.equal(s.toggle.textContent,'모션 재생');s.visibility(false);s.visibility(true);assert.equal(s.callbacks.size,0);s.toggle.handlers.click();assert.equal(s.callbacks.size,1);assert.equal(s.toggle.textContent,'모션 일시정지');s.preference.matches=true;s.events.preference();s.tick(300);assert.equal(s.toggle.hidden,true);assert.equal(s.callbacks.size,0);
s=setup(false,false);assert.equal(s.toggle.hidden,true);
console.log('PASS: manual pause/resume, pause persistence, reduced-motion static frame, offscreen/hidden pause, context loss and unavailable WebGL fallback.');
