import Foundation
import PDFKit
let root=CommandLine.arguments[1]
guard let doc=PDFDocument(url:URL(fileURLWithPath:root+"/assets/documents/taeho-kim-portfolio-a4.pdf")) else {fatalError("Cannot read exported PDF")}
precondition(doc.pageCount==9,"Expected nine pages")
var links=0
for i in 0..<doc.pageCount {
 let p=doc.page(at:i)!,b=p.bounds(for:.mediaBox)
 precondition(abs(b.width-595.2756)<0.1 && abs(b.height-841.8898)<0.1,"Page \(i+1) is not A4 portrait")
 precondition(!(p.string ?? "").isEmpty,"Empty page \(i+1)")
 links+=p.annotations.filter{$0.url != nil}.count
}
let text=(doc.string ?? "").replacingOccurrences(of:"\\s+",with:"",options:.regularExpression)
for required in ["김태호","sinzenight@gmail.com","선수인베스트먼트","CU옥수역점","PassiveSensing","FundusVision","TaxRAGLab","OpenCVPreprocessingAdvisor","SolarSentinels","결론유보","Codex","팀원이담당","2026.09.10","논문원문PDF는확보후","한신대학교","LG 경영개발원 AI 연구원".replacingOccurrences(of:" ",with:""),"SQL개발자","컴퓨터활용능력2급","사회조사분석사2급"] {
 precondition(text.contains(required),"Missing source text: \(required)")
}
precondition(links>=12,"Expected live document and repository links")
precondition(!text.contains("010-8620"),"Phone number must remain excluded")
print("PASS: nine nonempty A4 portrait pages, core source content/caveats, \(links) clickable links, no phone number.")
