import SwiftUI
import QuizCore

/// The main window: welcome → twenty questions → verdict, plus the settings button and feedback tab.
public struct ContentView: View {
    private enum Stage { case welcome, quiz, result }

    @AppStorage(PrefKey.shuffleAnswers) private var shuffleAnswers = true
    @AppStorage(PrefKey.speedScoring) private var speedScoring = true

    @State private var stage: Stage = .welcome
    @State private var session = QuizSession(questions: [])
    @State private var questionShownAt = Date()
    @State private var showFeedback = false
    @Environment(\.colorScheme) private var scheme

    public init() {}

    private var speedThreshold: Double? { speedScoring ? Scorer.defaultSpeedThreshold : nil }

    public var body: some View {
        let p = Palette.forScheme(scheme)
        ZStack(alignment: .bottomTrailing) {
            p.background.ignoresSafeArea()

            Group {
                switch stage {
                case .welcome:
                    WelcomeView(onStart: start)
                case .quiz:
                    if let q = session.current {
                        QuestionView(question: q, index: session.currentIndex, total: session.questions.count) { response in
                            pick(response)
                        }
                        .id(q.id)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                    }
                case .result:
                    ResultView(result: session.result(speedThreshold: speedThreshold), speedScoring: speedScoring, onRestart: start)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FeedbackTab { showFeedback = true }
                .padding(12)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                SettingsLink { Image(systemName: "gearshape") }
                    .help("Settings (⌘,)")
            }
        }
        .sheet(isPresented: $showFeedback) { FeedbackView() }
        .frame(minWidth: 720, minHeight: 680)
    }

    private func start() {
        session = QuizSession(shuffleAnswers: shuffleAnswers)
        questionShownAt = Date()
        withAnimation(.easeOut(duration: 0.25)) { stage = .quiz }
    }

    private func pick(_ response: Response) {
        session.answer(response, seconds: Date().timeIntervalSince(questionShownAt))
        questionShownAt = Date()
        withAnimation(.easeOut(duration: 0.25)) {
            if session.isFinished { stage = .result }
        }
    }
}

/// Small, quiet "Feedback" pill in the window's corner.
struct FeedbackTab: View {
    let action: () -> Void
    @State private var hovering = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = Palette.forScheme(scheme)
        Button(action: action) {
            Label("Feedback", systemImage: "bubble.left")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(hovering ? p.text : p.secondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(p.card.opacity(hovering ? 1 : 0.7)))
                .overlay(Capsule().strokeBorder(p.border))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help("Send feedback")
    }
}
