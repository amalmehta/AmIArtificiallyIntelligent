import SwiftUI
import QuizCore

/// One question, in whichever of the four formats it uses.
public struct QuestionView: View {
    let question: Question
    let index: Int
    let total: Int
    let onAnswer: (Response) -> Void

    @State private var selected: Set<String>
    @State private var text: String
    @State private var submitted = false
    @FocusState private var textFocused: Bool
    @Environment(\.colorScheme) private var scheme

    /// - Parameter prefill: pre-selects an answer without submitting it (used for screenshots).
    public init(question: Question, index: Int, total: Int, prefill: Response? = nil, onAnswer: @escaping (Response) -> Void) {
        self.question = question
        self.index = index
        self.total = total
        self.onAnswer = onAnswer
        switch prefill {
        case .choices(let ids): _selected = State(initialValue: ids)
        case .choice(let id): _selected = State(initialValue: [id])
        default: _selected = State(initialValue: [])
        }
        if case .text(let t) = prefill { _text = State(initialValue: t) } else { _text = State(initialValue: "") }
    }

    public var body: some View {
        let p = Palette.forScheme(scheme)
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                CategoryChip(category: question.category)
                Text(question.format.kind.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(p.secondaryText)
                Spacer()
                Text("Question \(index + 1) of \(total)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(p.secondaryText)
            }
            ProgressBar(fraction: Double(index) / Double(total), color: p.accent, track: p.border)

            VStack(alignment: .leading, spacing: 4) {
                if case .scale = question.format {
                    Text("How much do you agree?")
                        .font(.system(size: 13))
                        .foregroundStyle(p.secondaryText)
                }
                Text(question.prompt)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(p.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)

            answerArea(p)

            Spacer(minLength: 0)
            Text(hint)
                .font(.system(size: 11))
                .foregroundStyle(p.secondaryText)
        }
        .padding(32)
    }

    @ViewBuilder
    private func answerArea(_ p: Palette) -> some View {
        switch question.format {
        case .single(let options):
            VStack(spacing: 10) {
                ForEach(Array(options.enumerated()), id: \.element.id) { i, option in
                    ChoiceRow(number: i + 1, text: option.text, style: .single, isSelected: selected.contains(option.id)) {
                        submit(.choice(option.id))
                    }
                }
            }

        case .multiple(let options):
            VStack(spacing: 8) {
                ForEach(Array(options.enumerated()), id: \.element.id) { i, option in
                    ChoiceRow(number: i + 1, text: option.text, style: .checkbox, isSelected: selected.contains(option.id)) {
                        if selected.contains(option.id) { selected.remove(option.id) } else { selected.insert(option.id) }
                    }
                }
                HStack {
                    Spacer()
                    Button("Continue") { submit(.choices(selected)) }
                        .buttonStyle(PillButtonStyle(color: selected.isEmpty ? p.border : p.accent))
                        .disabled(selected.isEmpty)
                        .keyboardShortcut(.defaultAction)
                }
                .padding(.top, 6)
            }

        case .scale:
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { value in
                    ScaleButton(value: value, label: ScaleLabels.label(value)) { submit(.scale(value)) }
                }
            }

        case .text:
            VStack(alignment: .trailing, spacing: 10) {
                TextField("Type your answer…", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .foregroundStyle(p.text)
                    .lineLimit(3...8)
                    .focused($textFocused)
                    .onSubmit(submitText)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(p.card))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(textFocused ? p.accent.opacity(0.7) : p.border))
                Button("Continue", action: submitText)
                    .buttonStyle(PillButtonStyle(color: trimmed.isEmpty ? p.border : p.accent))
                    .disabled(trimmed.isEmpty)
            }
            .onAppear { textFocused = true }
        }
    }

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func submitText() {
        guard !trimmed.isEmpty else { return }
        submit(.text(text))
    }

    /// Guards against a double press answering the next question too.
    private func submit(_ response: Response) {
        guard !submitted else { return }
        submitted = true
        onAnswer(response)
    }

    private var hint: String {
        switch question.format {
        case .single: "Tip: press 1–\(question.options.count) to answer."
        case .multiple: "Tip: press 1–\(question.options.count) to tick, then Return to continue."
        case .scale: "Tip: press 1–5 to answer."
        case .text: "Press Return to continue. Your typing is scored on this Mac only."
        }
    }
}

struct ChoiceRow: View {
    enum Style { case single, checkbox }

    let number: Int
    let text: String
    let style: Style
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = Palette.forScheme(scheme)
        let highlighted = hovering || isSelected
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                if style == .checkbox {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .font(.system(size: 17))
                        .foregroundStyle(isSelected ? p.accent : p.secondaryText)
                }
                Text("\(number)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(p.accent)
                    .frame(width: 22, height: 22)
                    .background(RoundedRectangle(cornerRadius: 6).fill(p.accent.opacity(0.12)))
                Text(text)
                    .font(.system(size: 15))
                    .foregroundStyle(p.text)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, style == .checkbox ? 9 : 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? p.accent.opacity(0.10) : (hovering ? p.cardHover : p.card)))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(highlighted ? p.accent.opacity(0.6) : p.border))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .keyboardShortcut(KeyEquivalent(Character("\(number)")), modifiers: [])
        .onHover { hovering = $0 }
    }
}

struct ScaleButton: View {
    let value: Int
    let label: String
    let action: () -> Void
    @State private var hovering = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = Palette.forScheme(scheme)
        Button(action: action) {
            VStack(spacing: 8) {
                Text("\(value)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(p.accent)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(p.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 84)
            .padding(.horizontal, 6)
            .background(RoundedRectangle(cornerRadius: 12).fill(hovering ? p.cardHover : p.card))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(hovering ? p.accent.opacity(0.6) : p.border))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .keyboardShortcut(KeyEquivalent(Character("\(value)")), modifiers: [])
        .onHover { hovering = $0 }
    }
}
