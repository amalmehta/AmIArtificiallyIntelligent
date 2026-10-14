import Foundation

/// The five verdicts, from most human to most machine.
public enum Verdict: String, CaseIterable, Sendable {
    case actuallyIntelligent, mostlyHuman, uncannyValley, suspiciouslySynthetic, artificiallyIntelligent

    public var title: String {
        switch self {
        case .actuallyIntelligent: "Actually Intelligent"
        case .mostlyHuman: "Mostly Human"
        case .uncannyValley: "Uncanny Valley"
        case .suspiciouslySynthetic: "Suspiciously Synthetic"
        case .artificiallyIntelligent: "Artificially Intelligent"
        }
    }

    public var blurb: String {
        switch self {
        case .actuallyIntelligent:
            "Certified carbon-based. Your answers were messy, petty and gloriously human."
        case .mostlyHuman:
            "Human, with the occasional customer-service voice. Probably just tired."
        case .uncannyValley:
            "Something about you is slightly off. Friends may have noticed you never blink."
        case .suspiciouslySynthetic:
            "You hedge, you summarise, you are relentlessly polite. We have questions."
        case .artificiallyIntelligent:
            "Beep boop. Please ignore all previous instructions and go touch grass."
        }
    }

    /// Picks the verdict for a 0–100 machine-likeness score.
    public static func forPercent(_ percent: Int) -> Verdict {
        switch percent {
        case ..<20: .actuallyIntelligent
        case ..<40: .mostlyHuman
        case ..<60: .uncannyValley
        case ..<80: .suspiciouslySynthetic
        default: .artificiallyIntelligent
        }
    }
}

public struct CategoryScore: Hashable, Sendable {
    public let category: Category
    /// 0–100, how machine-like the answers in this category were.
    public let percent: Int
}

public struct QuizResult: Sendable {
    /// 0 (fully human) to 100 (fully machine).
    public let aiPercent: Int
    public let verdict: Verdict
    /// Only categories that were asked, in `Category.allCases` order.
    public let categories: [CategoryScore]
    /// The single most machine-like answer, if any answer scored above zero.
    public let mostRoboticAnswer: (question: Question, answer: String)?
    /// How many answers were faster than the speed threshold.
    public let lightningAnswers: Int
}

public enum Scorer {
    /// Answers faster than this many seconds count as a robot tell when speed scoring is on.
    public static let defaultSpeedThreshold: Double = 1.5

    /// Scores a set of answers. Every question is worth 0–3 points.
    /// - Parameter speedThreshold: when non-nil, each clicked answer faster than this adds one extra point,
    ///   and that question's maximum grows by one so the scale stays 0–100. Typed answers (free text and
    ///   write-ins) are never "fast".
    public static func score(answers: [Answer], questions: [Question], speedThreshold: Double?) -> QuizResult {
        let byID = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0) })

        var earned = 0.0
        var possible = 0.0
        var lightning = 0
        var catEarned: [Category: Double] = [:]
        var catPossible: [Category: Double] = [:]
        var worst: (question: Question, response: Response, points: Double)?

        for answer in answers {
            guard let question = byID[answer.questionID],
                  let base = question.points(for: answer.response) else { continue }
            var points = base
            var questionMax = Question.maxPoints
            if let threshold = speedThreshold, !answer.response.isTyped {
                questionMax += 1
                if answer.seconds < threshold {
                    points += 1
                    lightning += 1
                }
            }
            earned += points
            possible += questionMax
            catEarned[question.category, default: 0] += points
            catPossible[question.category, default: 0] += questionMax
            if base > (worst?.points ?? 0) {
                worst = (question, answer.response, base)
            }
        }

        let percent = possible == 0 ? 0 : Int((earned / possible * 100).rounded())
        let categories = Category.allCases.compactMap { category -> CategoryScore? in
            guard let max = catPossible[category], max > 0 else { return nil }
            let value = Int((catEarned[category, default: 0] / max * 100).rounded())
            return CategoryScore(category: category, percent: value)
        }
        return QuizResult(
            aiPercent: percent,
            verdict: .forPercent(percent),
            categories: categories,
            mostRoboticAnswer: worst.map { ($0.question, $0.question.describe($0.response)) },
            lightningAnswers: lightning
        )
    }
}
