import Foundation
import PDFKit
import AppKit
import CryptoKit

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let names = ["ictc", "fundus", "money", "rag", "opencv", "solar", "ictc-poster"]
var manifest: [String: Any] = [:]
for name in names {
    let source = root.appendingPathComponent("assets/documents/\(name).pdf")
    let data = try Data(contentsOf: source)
    guard let document = PDFDocument(data: data) else { fatalError("Invalid PDF: \(name)") }
    let folder = root.appendingPathComponent("assets/document-pages/\(name)")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    var pages: [[String: Any]] = []
    for index in 0..<document.pageCount {
        guard let page = document.page(at: index) else { fatalError("Missing page") }
        let bounds = page.bounds(for: .mediaBox)
        let width: CGFloat = name == "ictc-poster" ? 2800 : 1800
        let image = page.thumbnail(of: NSSize(width: width, height: width * bounds.height / bounds.width), for: .mediaBox)
        guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
              let jpg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.88]) else { fatalError("Render failed") }
        let filename = "page-\(index + 1).jpg"
        try jpg.write(to: folder.appendingPathComponent(filename))
        pages.append(["src": "./assets/document-pages/\(name)/\(filename)", "width": bitmap.pixelsWide, "height": bitmap.pixelsHigh, "text": page.string ?? ""])
    }
    manifest["\(name).pdf"] = ["pages": pages, "sha256": SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()]
    print("\(name): \(document.pageCount) pages")
}
let json = try JSONSerialization.data(withJSONObject: manifest, options: [.sortedKeys, .prettyPrinted])
try json.write(to: root.appendingPathComponent("assets/document-pages.json"))
