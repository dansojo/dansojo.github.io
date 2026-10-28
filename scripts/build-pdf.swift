import Foundation
import AppKit
import CoreText
import PDFKit

// Usage: swift scripts/build-pdf.swift content.json site-root output.pdf
let args = CommandLine.arguments
let data = try Data(contentsOf: URL(fileURLWithPath: args[1]))
let content = try JSONSerialization.jsonObject(with: data) as! [String: Any]
let root = URL(fileURLWithPath: args[2])
let output = URL(fileURLWithPath: args[3])
let W: CGFloat = 595.2756, H: CGFloat = 841.8898, margin: CGFloat = 44
let ink = NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.17, alpha: 1)
let muted = NSColor(calibratedRed: 0.38, green: 0.39, blue: 0.44, alpha: 1)
let accent = NSColor(calibratedRed: 0.39, green: 0.28, blue: 0.58, alpha: 1)
let line = NSColor(calibratedWhite: 0.86, alpha: 1)
let bodyWidth = W - margin * 2
var media = CGRect(x: 0, y: 0, width: W, height: H)
guard let consumer = CGDataConsumer(url: output as CFURL),
      let ctx = CGContext(consumer: consumer, mediaBox: &media,
        [kCGPDFContextTitle as String: "김태호 — 이력서 및 포트폴리오", kCGPDFContextAuthor as String: "김태호", kCGPDFContextSubject as String: "A4 통합 이력서 및 포트폴리오 · 자료 기준 2026.10.28"] as CFDictionary) else { fatalError("Cannot create PDF") }
var page = 0
var pageBottom: CGFloat = 0
var overflows: [String] = []
func string(_ d: [String:Any], _ key: String) -> String { d[key] as? String ?? "" }
func strings(_ d: [String:Any], _ key: String) -> [String] { d[key] as? [String] ?? [] }
func dicts(_ d: [String:Any], _ key: String) -> [[String:Any]] { d[key] as? [[String:Any]] ?? [] }
func attributed(_ text: String, size: CGFloat, bold: Bool = false, color: NSColor = ink) -> NSAttributedString {
  let style = NSMutableParagraphStyle(); style.lineSpacing = size * 0.34
  style.lineBreakMode = .byWordWrapping
  let font = NSFont(name: bold ? "AppleSDGothicNeo-SemiBold" : "AppleSDGothicNeo-Regular", size: size) ?? NSFont.systemFont(ofSize:size, weight:bold ? .semibold : .regular)
  return NSAttributedString(string:text, attributes:[.font:font, .foregroundColor:color, .paragraphStyle:style])
}
@discardableResult func text(_ value: String, x: CGFloat = margin, y: CGFloat, width: CGFloat = bodyWidth, size: CGFloat = 10, bold: Bool = false, color: NSColor = ink) -> CGFloat {
  if value.isEmpty { return y }
  let a = attributed(value, size:size, bold:bold, color:color)
  let fs = CTFramesetterCreateWithAttributedString(a)
  let fit = CTFramesetterSuggestFrameSizeWithConstraints(fs, CFRange(location:0,length:0), nil, CGSize(width:width,height:10000), nil)
  let height = ceil(fit.height) + 5
  let path = CGPath(rect:CGRect(x:x,y:H-y-height,width:width,height:height),transform:nil)
  let frame = CTFramesetterCreateFrame(fs,CFRange(location:0,length:0),path,nil)
  ctx.saveGState();ctx.textMatrix = .identity; CTFrameDraw(frame,ctx);ctx.restoreGState()
  pageBottom = max(pageBottom, y + height)
  return y + height
}
func rule(_ y: CGFloat) {
  ctx.setStrokeColor(line.cgColor);ctx.setLineWidth(0.5)
  ctx.move(to:CGPoint(x:margin,y:H-y));ctx.addLine(to:CGPoint(x:W-margin,y:H-y));ctx.strokePath()
}
func start(_ section: String) {
  page += 1;ctx.beginPDFPage(nil);ctx.setFillColor(NSColor.white.cgColor);ctx.fill(media)
  pageBottom = 0
  text("TAEHO KIM / PORTFOLIO",y:22,size:7,bold:true,color:accent)
  text(section,x:W-244,y:22,width:200,size:7,color:muted)
  rule(42)
}
func end() {
  if pageBottom > H-58 { overflows.append("Page \(page): bottom \(pageBottom)") }
  rule(H-40)
  // Footers are excluded from content-fit calculations.
  text("자료 기준 2026.10.28 · dansojo.github.io",y:H-30,size:7,color:muted)
  text(String(format:"%02d / 09",page),x:W-100,y:H-30,width:56,size:7,color:muted)
  ctx.endPDFPage()
}
func absolute(_ path: String) -> String {
  if path.hasPrefix("./") { return "https://dansojo.github.io/" + path.dropFirst(2) }
  return path
}
@discardableResult func link(_ label: String, url: String, y: CGFloat, x:CGFloat = margin, width:CGFloat = bodyWidth) -> CGFloat {
  let next = text(label,x:x,y:y,width:width,size:9,bold:true,color:accent)
  if let u=URL(string:absolute(url)) {ctx.setURL(u as CFURL,for:CGRect(x:x,y:H-next,width:width,height:next-y))}
  return next
}
func image(_ path: String, y: CGFloat, height: CGFloat) {
  let url = root.appendingPathComponent(path.replacingOccurrences(of:"./",with:""))
  guard let image=NSImage(contentsOf:url),let cg=image.cgImage(forProposedRect:nil,context:nil,hints:nil) else {fatalError("Missing image \(path)")}
  let ratio=min(bodyWidth/CGFloat(cg.width),height/CGFloat(cg.height))
  let w=CGFloat(cg.width)*ratio,h=CGFloat(cg.height)*ratio
  ctx.saveGState();ctx.setFillColor(NSColor(calibratedWhite:0.96,alpha:1).cgColor);ctx.fill(CGRect(x:margin,y:H-y-height,width:bodyWidth,height:height))
  ctx.draw(cg,in:CGRect(x:margin+(bodyWidth-w)/2,y:H-y-height+(height-h)/2,width:w,height:h));ctx.restoreGState()
  pageBottom=max(pageBottom,y+height)
}
func heading(_ title:String,_ label:String) -> CGFloat {
  var y=text(label,y:62,size:8,bold:true,color:accent)
  y=text(title,y:y+12,size:25,bold:true)
  return y+18
}

// 1. Identity, complete introduction and document guide.
start("PROFILE / DOCUMENT GUIDE")
var y=text("김태호",y:82,size:44,bold:true)
y=text("AI Development · Computer Vision · Data Analysis",y:y+4,size:12,color:accent)
y=text(string(content,"intro"),y:y+26,size:13)
for p in strings(content,"about") { y=text(p,y:y+15,size:11) }
y += 24;rule(y);y += 20
y=text("연락처와 작업 링크",y:y,size:13,bold:true)
y=link("이메일  ·  "+string(content,"email"),url:"mailto:"+string(content,"email"),y:y+12)
y=link("GitHub  ·  "+string(content,"github"),url:string(content,"github"),y:y+4)
y=link("웹 포트폴리오  ·  "+string(content,"site"),url:string(content,"site"),y:y+4)
y += 25;y=text("문서 구성",y:y,size:13,bold:true)
for item in ["02  경력 및 운영 경험", "03–06  대표 프로젝트 4개 · 기여·결과·평가 조건", "07  OpenCV · Solar 추가 프로젝트", "08  논문 및 발표 · ICTC 포스터", "09  학력·교육·기술·자격"] { y=text(item,y:y+7,size:10,color:muted) }
y=text("웹페이지 내용을 A4 세로형으로 정리한 통합본입니다. 개별 프로젝트 원본 PDF와 코드는 각 항목의 링크에서 확인할 수 있습니다. 논문 원문은 제공 자료에 없어 포함하지 않았습니다.",y:y+22,size:8.5,color:muted)
end()

// 2. Complete career entries.
start("EXPERIENCE")
y=heading("경력 및 운영 경험","BACKGROUND / 01")
for e in dicts(content,"experience") {
  y=text(string(e,"date"),y:y,size:9,bold:true,color:accent)
  y=text(string(e,"title"),y:y+8,size:19,bold:true)
  for p in strings(e,"paragraphs") {y=text(p,y:y+9,size:10.5)}
  for b in strings(e,"bullets") {y=text("• "+b,y:y+6,size:10.5)}
  y += 24;rule(y);y += 24
}
end()

// 3–6. Four complete website case studies including collapsed details.
for (i,p) in dicts(content,"projects").enumerated() {
  start("SELECTED WORK / 0\(i+1)")
  y=text(string(p,"meta"),y:59,size:7.5,bold:true,color:accent)
  y=text(string(p,"name"),y:y+8,size:25,bold:true)
  y=text(string(p,"heading"),y:y+3,size:13,bold:true)
  y=text(string(p,"description"),y:y+9,size:10)
  y=text(strings(p,"tags").joined(separator:"  /  "),y:y+6,size:8,color:accent)
  let imgTop=y+13
  image(string(p,"image"),y:imgTop,height:218)
  y=text(string(p,"caption"),y:imgTop+223,size:7.5,color:muted)
  y=text(strings(p,"metrics").joined(separator:"    |    "),y:y+10,size:10,bold:true,color:accent)
  for d in dicts(p,"details") {
    y=text(string(d,"title"),y:y+10,size:8.5,bold:true,color:accent)
    y=text(string(d,"body"),y:y+3,size:9)
  }
  for l in dicts(p,"links") {y=link(string(l,"title")+" ↗",url:string(l,"url"),y:y+7)}
  end()
}

// 7. Additional projects with all implementation caveats.
start("MORE EXPLORATIONS")
y=heading("비교하고, 선택한 기록","ADDITIONAL PROJECTS")
for e in dicts(content,"extra") {
  y=text(string(e,"meta"),y:y,size:8,bold:true,color:accent)
  y=text(string(e,"title"),y:y+8,size:18,bold:true)
  for p in strings(e,"paragraphs") {y=text(p,y:y+12,size:10.5)}
  y=text(string(e,"metric"),y:y+12,size:11,bold:true,color:accent)
  y=link("프로젝트 원본 PDF ↗",url:string(e,"pdf"),y:y+14)
  y += 24;rule(y);y += 24
}
end()

// 8. Research and vector poster, clearly distinguished from the paper.
start("RESEARCH & PUBLICATION")
let paper=content["publication"] as! [String:Any]
y=text("논문 및 발표",y:60,size:24,bold:true)
y=text(string(paper,"title"),y:y+12,size:19,bold:true)
y=text(string(paper,"subtitle"),y:y+4,size:10,color:accent)
for p in strings(paper,"paragraphs") { y=text(p,y:y+9,size:9.5) }
for l in dicts(paper,"links") { y=link(string(l,"title")+" ↗",url:string(l,"url"),y:y+5) }
let posterTop=y+15
let posterHeight=min(350,H-65-posterTop)
guard let poster=PDFDocument(url:root.appendingPathComponent("assets/documents/ictc-poster.pdf"))?.page(at:0) else {fatalError("Missing poster")}
let box=poster.bounds(for:.mediaBox)
let scale=min(bodyWidth/box.width,posterHeight/box.height)
ctx.saveGState();ctx.translateBy(x:margin+(bodyWidth-box.width*scale)/2,y:H-posterTop-box.height*scale);ctx.scaleBy(x:scale,y:scale);poster.draw(with:.mediaBox,to:ctx);ctx.restoreGState()
pageBottom=max(pageBottom,posterTop+box.height*scale)
end()

// 9. Education, technologies and certificates in full.
start("EDUCATION / SKILLS")
y=heading("학력 · 교육 · 기술","BACKGROUND / 02")
for e in dicts(content,"education") {
  y=text(string(e,"date"),y:y,size:8,bold:true,color:accent)
  y=text(string(e,"title"),y:y+4,size:12,bold:true)
  for p in strings(e,"paragraphs") { y=text(p,y:y+3,size:9) }
  y += 13
}
rule(y);y += 16
for s in dicts(content,"skills") {
  y=text(string(s,"title"),y:y,size:9,bold:true,color:accent)
  y=text(strings(s,"items").joined(separator:" · "),y:y+4,size:9)
  y += 11
}
y=text(string(content,"skillsNote"),y:y,size:8,color:muted)
y=text("자격",y:y+14,size:11,bold:true)
for c in strings(content,"certificates") { y=text(c,y:y+5,size:9) }
end()
ctx.closePDF()
if !overflows.isEmpty { fputs("Content overflow: \(overflows.joined(separator:", "))\n",stderr);exit(1) }
print("Built \(page)-page A4 PDF: \(output.path)")
