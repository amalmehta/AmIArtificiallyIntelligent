import SwiftUI
import QuizCore

/// Every preference in one place. Opened with ⌘, or the gear button.
public struct SettingsView: View {
    @AppStorage(PrefKey.shuffleAnswers) private var shuffleAnswers = true
    @AppStorage(PrefKey.speedScoring) private var speedScoring = true
    @AppStorage(PrefKey.appearance) private var appearance = Appearance.system.rawValue

    public init() {}

    public var body: some View {
        Form {
            Section {
                Toggle("Shuffle answer order", isOn: $shuffleAnswers)
            } header: {
                Text("Questions")
            } footer: {
                Text("Each run draws \(QuizSession.defaultCount) of \(QuestionBank.all.count) questions at random.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                Toggle("Count lightning-fast answers as a robot tell", isOn: $speedScoring)
            } header: {
                Text("Scoring")
            } footer: {
                Text("Answers clicked in under \(Scorer.defaultSpeedThreshold.formatted()) seconds add a point toward \u{201C}Artificially Intelligent.\u{201D} Typed answers never count. Takes effect on the next run.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Appearance") {
                Picker("Theme", selection: $appearance) {
                    ForEach(Appearance.allCases) { Text($0.title).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
            }
            Section("Feedback") {
                LabeledContent("Saved to") {
                    Text(FeedbackStore.shared.fileURL.path(percentEncoded: false))
                        .font(.caption)
                        .textSelection(.enabled)
                        .lineLimit(2)
                }
                Button("Show Feedback File in Finder") { FeedbackStore.shared.revealInFinder() }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }
}
