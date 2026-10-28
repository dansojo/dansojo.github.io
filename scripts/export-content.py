# -*- coding: utf-8 -*-
"""Extract the printable portfolio from the current website without dependencies."""
from html.parser import HTMLParser
from pathlib import Path
import json,re,sys
class Node:
 def __init__(self,tag='',attrs=()):self.tag=tag;self.a=dict(attrs);self.children=[]
 def all(self,tag=None,cls=None,id=None):
  out=[]
  for c in self.children:
   if isinstance(c,Node):
    if (tag is None or c.tag==tag) and (cls is None or cls in c.a.get('class','').split()) and (id is None or c.a.get('id')==id):out.append(c)
    out+=c.all(tag,cls,id)
  return out
 def one(self,**kw):return self.all(**kw)[0]
 def text(self):
  return re.sub(r'\s+',' ',' '.join(c.text() if isinstance(c,Node) else c for c in self.children)).strip()
class Parser(HTMLParser):
 def __init__(self):super().__init__();self.root=Node();self.stack=[self.root]
 def handle_starttag(self,t,a):
  if t=='br':self.stack[-1].children.append(' ');return
  n=Node(t,a);self.stack[-1].children.append(n)
  if t not in ['meta','link','img','input','hr','source','wbr']:self.stack.append(n)
 def handle_endtag(self,t):
  for i in range(len(self.stack)-1,0,-1):
   if self.stack[i].tag==t:self.stack=self.stack[:i];break
 def handle_data(self,t):self.stack[-1].children.append(t)
r=Path(__file__).resolve().parents[1];parser=Parser();parser.feed((r/'index.html').read_text());doc=parser.root
work=[]
for n in doc.all(cls='work'):
 work.append(dict(name=n.one(cls='work-name').text(),heading=n.one(tag='h3').text(),meta=n.one(cls='work-heading').text(),description=n.one(cls='work-description').text(),tags=[x.text() for x in n.one(cls='tags').all(tag='span')],metrics=[x.text() for x in n.one(cls='work-metrics').all(tag='div')],image=n.one(tag='img').a['src'],caption=n.one(cls='work-visual').one(tag='p').text(),details=[dict(title=x.one(tag='h4').text(),body=x.one(tag='p').text()) for x in n.one(cls='deep-grid').all(tag='div')],links=[dict(title=x.a.get('data-pdf',x.text()),url=x.a['href']) for x in n.one(cls='work-actions').all(tag='a')]))
def timeline(id):
 return [dict(date=n.one(cls='period').text(),title=n.one(tag='h3').text(),paragraphs=[x.text() for x in n.all(tag='p') if 'period' not in x.a.get('class','')],bullets=[x.text() for x in n.all(tag='li')]) for n in doc.one(id=id).all(cls='timeline-item')]
extra=[]
for n in doc.one(cls='more-work').all(tag='article'):
 extra.append(dict(title=n.one(tag='h4').text(),meta=n.one(cls='small-label').text(),paragraphs=[x.text() for x in n.all(tag='p')],metric=n.one(cls='mini-result').text(),pdf=n.one(tag='a').a['href']))
paper=doc.one(cls='paper-content');skills=doc.one(id='skills')
data=dict(name='김태호',englishName='TAEHO KIM',email='sinzenight@gmail.com',github='https://github.com/dansojo',site='https://dansojo.github.io/',sourceDate='2026.10.28',intro=doc.one(cls='hero-description').text(),about=[x.text() for x in doc.one(id='about').all(tag='p') if 'eyebrow' not in x.a.get('class','')],projects=work,experience=timeline('experience'),education=timeline('education'),extra=extra,publication=dict(title=paper.one(tag='h3').text(),subtitle=paper.one(cls='paper-subtitle').text(),paragraphs=[x.text() for x in paper.all(tag='p') if 'paper-subtitle' not in x.a.get('class','')],links=[dict(title=x.a.get('data-pdf',x.text()),url=x.a['href']) for x in paper.one(cls='paper-actions').all(tag='a')]),skills=[dict(title=n.one(tag='h3').text(),items=[x.text() for x in n.all(tag='span')]) for n in skills.all(cls='skill-group')],skillsNote=skills.one(cls='fine-print').text(),certificates=[x.text() for x in skills.one(cls='certificates').all(tag='p')])
Path(sys.argv[1]).write_text(json.dumps(data,ensure_ascii=False,indent=2))
print('Exported current website content, including all collapsed project details.')
