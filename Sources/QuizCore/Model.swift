import Foundation

/// A group of related categories. Categories in the same family share a hue family in the UI.
public enum Family: String, CaseIterable, Sendable {
    case thinking, heart, tells

    public var title: String {
        switch self {
        case .thinking: "Thinking"
        case .heart: "Heart"
        case .tells: "Machine Tells"
        }
    }
}

/// What a question probes.
public enum Category: String, CaseIterable, Sendable, Codable {
    case reasoning, commonSense
    case feelings, selfAwareness, creativity
    case hedging, verbosity

    public var title: String {
        switch self {
        case .reasoning: "Reasoning"
        case .commonSense: "Common Sense"
        case .feelings: "Feelings"
        case .selfAwareness: "Self-Awareness"
        case .creativity: "Creativity"
        case .hedging: "Hedging"
        case .verbosity: "Verbosity"
        }
    }

    public var family: Family {
        switch self {
        case .reasoning, .commonSense: .thinking
        case .feelings, .selfAwareness, .creativity: .heart
        case .hedging, .verbosity: .tells
        }
    }
}

public struct Option: Identifiable, Hashable, Sendable {
    public let id: String
    public let text: String
    /// How machine-like this answer is: 0 (thoroughly human) to 3 (unmistakably artificial).
    public let aiWeight: Int

    public init(id: String, text: String, aiWeight: Int) {
        precondition((0...Option.maxWeight).contains(aiWeight), "aiWeight out of range")
        self.id = id
        self.text = text
        self.aiWeight = aiWeight
    }

    public static let maxWeight = 3
}

/// The four ways a question can be answered.
public enum Format: Hashable, Sendable {
    /// Pick exactly one option.
    case single([Option])
    /// Pick all that apply.
    case multiple([Option])
    /// Rate a statement 1 (strongly disagree) to 5 (strongly agree).
    /// `machineAgrees` says which end is the robotic one.
    case scale(machineAgrees: Bool)
    /// Type a short answer; scored by `TextScorer`.
    case text

    public enum Kind: String, CaseIterable, Sendable {
        case single, multiple, scale, text

        public var title: String {
            switch self {
            case .single: "Pick One"
            case .multiple: "Pick All That Apply"
            case .scale: "Agree or Disagree"
            case .text: "In Your Own Words"
            }
        }
    }

    public var kind: Kind {
        switch self {
        case .single: .single
        case .multiple: .multiple
        case .scale: .scale
        case .text: .text
        }
    }

    public var options: [Option] {
        switch self {
        case .single(let o), .multiple(let o): o
        case .scale, .text: []
        }
    }
}

/// What someone answered.
public enum Response: Hashable, Sendable {
    case choice(String)
    case choices(Set<String>)
    case scale(Int)
    case text(String)
}

public enum ScaleLabels {
    public static let all = ["Strongly disagree", "Disagree", "Not sure", "Agree", "Strongly agree"]
    public static func label(_ value: Int) -> String { all[min(max(value, 1), 5) - 1] }
}

public struct Question: Identifiable, Hashable, Sendable {
    public let id: String
    public let category: Category
    public let prompt: String
    public let format: Format

    public init(id: String, category: Category, prompt: String, format: Format) {
        self.id = id
        self.category = category
        self.prompt = prompt
        self.format = format
    }

    public var options: [Option] { format.options }

    public func option(withID id: String) -> Option? {
        options.first { $0.id == id }
    }

    /// Every question is worth 0…`maxPoints` machine points.
    public static let maxPoints = Double(Option.maxWeight)

    /// Machine points for a response, or nil if the response doesn't fit this question.
    public func points(for response: Response) -> Double? {
        switch (format, response) {
        case (.single, .choice(let id)):
            return option(withID: id).map { Double($0.aiWeight) }
        case (.multiple(let opts), .choices(let ids)):
            guard !ids.isEmpty, ids.allSatisfy({ option(withID: $0) != nil }) else { return nil }
            let possible = opts.reduce(0) { $0 + $1.aiWeight }
            guard possible > 0 else { return 0 }
            let picked = opts.filter { ids.contains($0.id) }.reduce(0) { $0 + $1.aiWeight }
            return Question.maxPoints * Double(picked) / Double(possible)
        case (.scale(let machineAgrees), .scale(let value)):
            guard (1...5).contains(value) else { return nil }
            let agreement = Double(value - 1) / 4
            return Question.maxPoints * (machineAgrees ? agreement : 1 - agreement)
        case (.text, .text(let text)):
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return TextScorer.score(text)
        default:
            return nil
        }
    }

    /// The answer as a person would read it back.
    public func describe(_ response: Response) -> String {
        switch response {
        case .choice(let id):
            return option(withID: id)?.text ?? ""
        case .choices(let ids):
            return options.filter { ids.contains($0.id) }.map(\.text).joined(separator: " · ")
        case .scale(let value):
            return ScaleLabels.label(value)
        case .text(let text):
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

/// One recorded answer.
public struct Answer: Hashable, Sendable {
    public let questionID: String
    public let response: Response
    /// Seconds between the question appearing and the answer being given.
    public let seconds: Double

    public init(questionID: String, response: Response, seconds: Double) {
        self.questionID = questionID
        self.response = response
        self.seconds = seconds
    }
}
