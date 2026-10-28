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
let W: CGFloat = 595.2756, H: CGFloat = 841.8898, margin: CGFloat = 36
let ink = NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.17, alpha: 1)
let muted = NSColor(calibratedRed: 0.38, green: 0.39, blue: 0.44, alpha: 1)
let accent = NSColor(calibratedRed: 0.39, green: 0.28, blue: 0.58, alpha: 1)
let line = NSColor(calibratedWhite: 0.86, alpha: 1)
let bodyWidth = W - margin * 2
var media = CGRect(x: 0, y: 0, width: W, height: H)
guard let consumer = CGDataConsumer(url: output as CFURL),
      let ctx = CGContext(consumer: consumer, mediaBox: &media,
        [kCGPDFContextTitle as String: "김태호 — Resume / CV", kCGPDFContextAuthor as String: "김태호", kCGPDFContextSubject as String: "A4 1페이지 이력서 · 자료 기준 2026.10.28"] as CFDictionary) else { fatalError("Cannot create PDF") }
var page = 0
var pageBottom: CGFloat = 0
var overflows: [String] = []
func string(_ d: [String:Any], _ key: String) -> String { d[key] as? String ?? "" }
func strings(_ d: [String:Any], _ key: String) -> [String] { d[key] as? [String] ?? [] }
func dicts(_ d: [String:Any], _ key: String) -> [[String:Any]] { d[key] as? [[String:Any]] ?? [] }
func attributed(_ text: String, size: CGFloat, bold: Bool = false, color: NSColor = ink) -> NSAttributedString {
  let style = NSMutableParagraphStyle(); style.lineSpacing = size * 0.22
  style.lineBreakMode = .byWordWrapping
  let font = NSFont(name: bold ? "AppleSDGothicNeo-SemiBold" : "AppleSDGothicNeo-Regular", size: size) ?? NSFont.systemFont(ofSize:size, weight:bold ? .semibold : .regular)
  return NSAttributedString(string:text, attributes:[.font:font, .foregroundColor:color, .paragraphStyle:style])
}
@discardableResult func text(_ value: String, x: CGFloat = margin, y: CGFloat, width: CGFloat = bodyWidth, size: CGFloat = 10, bold: Bool = false, color: NSColor = ink) -> CGFloat {
  if value.isEmpty { return y }
  let a = attributed(value, size:size, bold:bold, color:color)
  let fs = CTFramesetterCreateWithAttributedString(a)
  let fit = CTFramesetterSuggestFrameSizeWithConstraints(fs, CFRange(location:0,length:0), nil, CGSize(width:width,height:10000), nil)
  let height = ceil(fit.height) + 2
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
  text(String(format:"%02d / 01",page),x:W-100,y:H-30,width:56,size:7,color:muted)
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

func section(_ label:String,_ y:CGFloat)->CGFloat {
  let next=text(label,y:y,size:10.5,bold:true,color:accent)
  rule(next+3)
  return next+10
}
func entry(_ title:String,_ detail:String,_ y:CGFloat)->CGFloat {
  let next=text(title,y:y,size:9.7,bold:true)
  return text(detail,y:next+3,size:9.1)+10
}
ctx.beginPDFPage(nil);ctx.setFillColor(NSColor.white.cgColor);ctx.fill(media)
var y=text("김태호",y:34,size:27,bold:true)
text("RESUME / CV",x:W-150,y:44,width:114,size:8,bold:true,color:accent)
y=text("AI Development · Computer Vision · Data Analysis",y:y+3,size:10,color:accent)
let contactY=y+7
link("sinzenight@gmail.com",url:"mailto:sinzenight@gmail.com",y:contactY,x:margin,width:180)
link("github.com/dansojo",url:"https://github.com/dansojo",y:contactY,x:margin+190,width:155)
y=link("dansojo.github.io ↗",url:"https://dansojo.github.io/",y:contactY,x:margin+365,width:158)+12
y=text("응용통계와 매입·재고·매출 관리 경험을 바탕으로 데이터 분석, 모델 검증, AI 도구 구현을 연결합니다.",y:y,size:9.5)+12

y=section("핵심 역량",y)
y=text("Python · SQL · Pandas · NumPy · Scikit-learn · PyTorch · OpenCV · Grad-CAM",y:y,size:9.1)
y=text("Azure · Streamlit · Gradio · LangChain · Qdrant · FastAPI  |  데이터 정제 · 모델 평가 · AI 도구 활용",y:y+3,size:9.1)+14

y=section("연구 및 프로젝트",y)
y=entry("ICTC 2026 센서 결측 구조 연구  |  2026 · 단독 저자 · 10.15 포스터 발표", "ETRI 10명에서 동일 삭제량의 결측 패턴을 비교했습니다. 상태 비율·강도 오차 차이 중앙값 0.463·0.376. 전체 결론 유보. 실험·코드·검증·집필에 AI 도구 활용, 복원 후 예측 성능 향상은 미검증.",y)
y=text("Beyond Missingness Rate: Structured Stress Testing and Feature Contracts for Passive Sensing Data",y:y-6,size:7.6,color:muted)+10
y=entry("Fundus Vision  |  2026.02–04 · 개인", "안저 10개 클래스의 불균형 대응 전략 비교, 오류 분석, Grad-CAM·Gradio 데모 구현. 내부 3,249장 평가 Accuracy 86.98%, Macro F1 0.8992. 분할 독립성·외부 임상 검증은 미확인.",y)
y=entry("Money Football  |  2026.06 · 팀 / PM", "5개 리그·96개 팀 데이터 수집·정제, Scout 백엔드 공동 구현, Azure 환경 구성·역할 조율. 예측 2,453건·24개 SHAP 변수 전달. 모델 학습·평가는 팀원이 담당했습니다.",y)
y=entry("Tax RAG Lab  |  2026.09–진행 중 · 개인", "제품 범위·모델·예산·답변 흐름을 검토하고 Codex가 구현·검증을 지원했습니다. 내부 9문항 Recall@5 0.667→1.000. 로컬·소규모 평가이며 세부 수치는 2026.09.10 기준, 실제 사용자 효과는 미검증.",y)
y=entry("OpenCV Preprocessing Advisor  |  2026.08 · 개인", "117장·6개 상태의 5-fold RTrees 비교에서 Macro F1 원본 0.789 / CLAHE+Bilateral 0.731. 이 조건에서는 원본을 유지했습니다. 공식 이상 탐지 평가가 아닙니다.",y)

y=section("경력",y+1)
y=entry("(주)선수인베스트먼트  |  운영총괄 매니저  |  2025.05–2026.05", "청과 매장 매입·발주·재고·판매·정산 총괄, 판매 흐름·원가 기반 운영 조정. 근무 종료 후 2026.09 AI 개발 도구로 장부 웹앱을 제작하고 실제 자료와 대조·개선했습니다.",y)
y=entry("CU 옥수역점  |  점장 및 매장 운영  |  2018.01–2022.01", "상품 발주·재고·매출, 고객 응대, 근무 일정 및 점포 운영 전반 담당.",y)

y=section("학력 및 교육",y+1)
y=text("한신대학교 응용통계학과 학사  |  2014.03–2022.02",y:y,size:9.3,bold:true)
y=text("SeSAC·Microsoft Azure AI 서비스 개발 과정 수료  |  2026.05–08",y:y+5,size:9.1)
y=text("LG Aimers · LG경영개발원 AI연구원  |  2024.01–02",y:y+3,size:9.1)
y=text("멀티캠퍼스 AI 융복합 프로젝트 교육  |  2022.01–06",y:y+3,size:9.1)+12

y=section("자격",y)
y=text("SQL 개발자 (2023.10) · 컴퓨터활용능력 2급 · 사회조사분석사 2급",y:y,size:9.1)
if y>H-53 {fputs("One-page resume overflow: \(y)\n",stderr);exit(1)}
rule(H-39)
text("상세 프로젝트·평가 조건·발표 자료: dansojo.github.io",y:H-30,size:7,color:muted)
text("2026.10.28 · 1 / 1",x:W-150,y:H-30,width:114,size:7,color:muted)
ctx.endPDFPage();ctx.closePDF()
print("Built one-page A4 Resume/CV, content bottom: \(y), output: \(output.path)")
