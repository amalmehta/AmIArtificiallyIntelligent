import Foundation

/// One run through the questionnaire: the drawn questions and the answers so far.
public struct QuizSession: Sendable {
    /// Questions asked per run.
    public static let defaultCount = 20

    public private(set) var questions: [Question]
    public private(set) var answers: [Answer] = []

    /// Uses `questions` as given, in order (handy for tests and previews).
    public init(questions: [Question]) {
        self.questions = questions
    }

    public init<G: RandomNumberGenerator>(
        pool: [Question] = QuestionBank.all,
        count: Int = QuizSession.defaultCount,
        shuffleAnswers: Bool,
        using rng: inout G
    ) {
        var qs = QuestionBank.draw(count: count, from: pool, using: &rng)
        if shuffleAnswers {
            qs = qs.map { q in
                switch q.format {
                case .single(let o):
                    return Question(id: q.id, category: q.category, prompt: q.prompt, format: .single(o.shuffled(using: &rng)))
                case .multiple(let o):
                    return Question(id: q.id, category: q.category, prompt: q.prompt, format: .multiple(o.shuffled(using: &rng)))
                case .scale, .text:
                    return q
                }
            }
        }
        questions = qs
    }

    public init(count: Int = QuizSession.defaultCount, shuffleAnswers: Bool) {
        var rng = SystemRandomNumberGenerator()
        self.init(count: count, shuffleAnswers: shuffleAnswers, using: &rng)
    }

    public var currentIndex: Int { answers.count }
    public var isFinished: Bool { answers.count >= questions.count }
    public var current: Question? { isFinished ? nil : questions[currentIndex] }

    /// Records an answer to the current question. Ignored if the quiz is over or the response doesn't fit.
    public mutating func answer(_ response: Response, seconds: Double) {
        guard let q = current, q.points(for: response) != nil else { return }
        answers.append(Answer(questionID: q.id, response: response, seconds: seconds))
    }

    public func result(speedThreshold: Double?) -> QuizResult {
        Scorer.score(answers: answers, questions: questions, speedThreshold: speedThreshold)
    }
}
