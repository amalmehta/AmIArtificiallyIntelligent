// Renders the README screenshots from the real views, offline, with fixed answers.
// Usage: swift run ScreenshotRenderer [output-dir]   (default: docs/images)
import SwiftUI
import AppKit
import QuizCore
import QuizUI

let outDir = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "docs/images", isDirectory: true)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

@MainActor
func render<V: View>(_ view: V, scheme: ColorScheme, name: String, size: CGSize = CGSize(width: 720, height: 620)) throws {
    let p = Palette.forScheme(scheme)
    let framed = ZStack { p.background; view }
        .frame(width: size.width, height: size.height)
        .environment(\.colorScheme, scheme)
        .environment(\.isStaticRender, true)
    let renderer = ImageRenderer(content: framed)
    renderer.scale = 2
    guard let image = renderer.nsImage,
          let tiff = image.tiffRepresentation,
          let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "ScreenshotRenderer", code: 1, userInfo: [NSLocalizedDescriptionKey: "render failed: \(name)"])
    }
    let url = outDir.appendingPathComponent("\(name).png")
    try png.write(to: url)
    print("wrote \(url.path)")
}

try MainActor.assumeIsolated {
    let bank = QuestionBank.all
    func q(_ id: String) -> Question { bank.first { $0.id == id }! }

    // A plausible, mostly-human run of 20 with a few robotic slips.
    let picks: [(String, Response)] = [
        ("hotdog", .choice("d")), ("toast", .choice("a")), ("monday", .choice("a")), ("weekend", .choice("d")),
        ("batball", .choice("c")), ("captcha", .choice("a")), ("roses", .choice("b")), ("strawberry", .choice("c")),
        ("fine", .choice("a")), ("what", .choice("a")),
        ("phrases", .choices(["a", "d"], writeIn: "Bold of you to assume I talk to people.")), ("texting", .choices(["a", "e"])), ("bands", .choices(["b", "c"])), ("cry", .choices(["b"])),
        ("commercials", .scale(4)), ("twosides", .scale(4)), ("glassdoor", .scale(5)), ("multiply", .scale(1)),
        ("socks", .text("my left sock has trust issues")), ("sunday", .text("Brunch, a long walk, and an early night.")),
    ]
    let questions = picks.map { q($0.0) }
    let answers = picks.map { Answer(questionID: $0.0, response: $0.1, seconds: 4) }
    let result = Scorer.score(answers: answers, questions: questions, speedThreshold: Scorer.defaultSpeedThreshold)
    let size = CGSize(width: 720, height: 740)

    for scheme in [ColorScheme.light, .dark] {
        let suffix = scheme == .dark ? "dark" : "light"
        try render(WelcomeView(onStart: {}), scheme: scheme, name: "welcome-\(suffix)", size: size)
        try render(QuestionView(question: q("phrases"), index: 6, total: 20, prefill: .choices(["a", "d"], writeIn: "\u{201C}Bold of you to assume I talk to people.\u{201D}"), onAnswer: { _ in }),
                   scheme: scheme, name: "question-multiple-\(suffix)", size: size)
        try render(QuestionView(question: q("commercials"), index: 11, total: 20, onAnswer: { _ in }),
                   scheme: scheme, name: "question-scale-\(suffix)", size: size)
        try render(ResultView(result: result, speedScoring: true, scrollable: false, onRestart: {}),
                   scheme: scheme, name: "result-\(suffix)", size: CGSize(width: 720, height: 760))
    }
}
