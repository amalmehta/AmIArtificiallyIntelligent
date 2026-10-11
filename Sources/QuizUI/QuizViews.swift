import SwiftUI
import QuizCore

// MARK: - Welcome

public struct WelcomeView: View {
    let onStart: () -> Void
    @Environment(\.colorScheme) private var scheme

    public init(onStart: @escaping () -> Void) { self.onStart = onStart }

    public var body: some View {
        let p = Palette.forScheme(scheme)
        VStack(spacing: 22) {
            HStack(spacing: 14) {
                Image(systemName: "brain.head.profile").foregroundStyle(p.human)
                Text("or").font(.system(size: 18, weight: .medium)).foregroundStyle(p.secondaryText)
                Image(systemName: "cpu").foregroundStyle(p.machine)
            }
            .font(.system(size: 44))

            VStack(spacing: 8) {
                Text("Am I Artificially Intelligent?")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(p.text)
                Text("Twenty questions. Four ways to answer. One uncomfortable verdict.")
                    .font(.system(size: 16))
                    .foregroundStyle(p.secondaryText)
            }

            HStack(spacing: 6) {
                ForEach(QuizCore.Category.allCases, id: \.self) { CategoryChip(category: $0) }
            }
            .padding(.top, 4)

            Button("Start the Test", action: onStart)
                .buttonStyle(PillButtonStyle(color: p.accent))
                .keyboardShortcut(.defaultAction)
                .padding(.top, 8)

            Text("About five minutes, different every time. Answer honestly — or don't, that's very human too.")
                .font(.system(size: 12))
                .foregroundStyle(p.secondaryText)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ProgressBar: View {
    let fraction: Double
    let color: Color
    let track: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track.opacity(0.6))
                Capsule().fill(color).frame(width: max(6, geo.size.width * fraction))
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Result

public struct ResultView: View {
    let result: QuizResult
    let speedScoring: Bool
    let onRestart: () -> Void
    let scrollable: Bool
    @Environment(\.colorScheme) private var scheme

    /// - Parameter scrollable: false only for offline rendering, since `ImageRenderer` can't draw a ScrollView.
    public init(result: QuizResult, speedScoring: Bool, scrollable: Bool = true, onRestart: @escaping () -> Void) {
        self.result = result
        self.speedScoring = speedScoring
        self.scrollable = scrollable
        self.onRestart = onRestart
    }

    public var body: some View {
        if scrollable {
            ScrollView { content }
        } else {
            content
        }
    }

    private var content: some View {
        let p = Palette.forScheme(scheme)
        let leansMachine = result.aiPercent >= 50
        return VStack(spacing: 22) {
                VStack(spacing: 8) {
                    Image(systemName: leansMachine ? "cpu" : "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundStyle(leansMachine ? p.machine : p.human)
                    Text("You are…").font(.system(size: 14)).foregroundStyle(p.secondaryText)
                    Text(result.verdict.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(p.text)
                    Text(result.verdict.blurb)
                        .font(.system(size: 15))
                        .foregroundStyle(p.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Meter(percent: result.aiPercent, palette: p)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Where the machine showed through")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(p.text)
                    ForEach(result.categories, id: \.category) { score in
                        CategoryBar(score: score, palette: p)
                    }
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 14).fill(p.card))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(p.border))

                if let worst = result.mostRoboticAnswer {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your most robotic answer")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(p.text)
                        Text(worst.question.prompt)
                            .font(.system(size: 12))
                            .foregroundStyle(p.secondaryText)
                        Text("\u{201C}\(worst.answer)\u{201D}")
                            .font(.system(size: 15, design: .serif).italic())
                            .foregroundStyle(p.machine)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 14).fill(p.card))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(p.border))
                }

                if speedScoring && result.lightningAnswers > 0 {
                    Text("⚡️ \(result.lightningAnswers) answer\(result.lightningAnswers == 1 ? " was" : "s were") suspiciously fast.")
                        .font(.system(size: 12))
                        .foregroundStyle(p.secondaryText)
                }

                Button("Take It Again", action: onRestart)
                    .buttonStyle(PillButtonStyle(color: p.accent))
                    .keyboardShortcut(.defaultAction)
            }
            .padding(32)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
    }
}

struct Meter: View {
    let percent: Int
    let palette: Palette

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(LinearGradient(colors: [palette.human, palette.machine], startPoint: .leading, endPoint: .trailing))
                    Circle()
                        .fill(palette.card)
                        .overlay(Circle().strokeBorder(palette.text, lineWidth: 3))
                        .frame(width: 22, height: 22)
                        .offset(x: (geo.size.width - 22) * Double(percent) / 100)
                }
            }
            .frame(height: 22)
            HStack {
                Text("Actually Intelligent").foregroundStyle(palette.human)
                Spacer()
                Text("\(percent)% machine").foregroundStyle(palette.text).fontWeight(.semibold)
                Spacer()
                Text("Artificially Intelligent").foregroundStyle(palette.machine)
            }
            .font(.system(size: 12, weight: .medium))
        }
    }
}

struct CategoryBar: View {
    let score: CategoryScore
    let palette: Palette
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let c = CategoryColors.color(score.category, scheme)
        HStack(spacing: 10) {
            Text(score.category.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(c)
                .frame(width: 104, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(palette.border.opacity(0.5))
                    Capsule().fill(c).frame(width: max(4, geo.size.width * Double(score.percent) / 100))
                }
            }
            .frame(height: 8)
            Text("\(score.percent)%")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(palette.secondaryText)
                .frame(width: 40, alignment: .trailing)
        }
    }
}
