import XCTest
@testable import QuizCore

/// Deterministic generator so shuffles are repeatable in tests.
struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

/// The most human and most machine-like response to a question.
func extremes(_ q: Question) -> (human: Response, machine: Response) {
    switch q.format {
    case .single(let o):
        return (.choice(o.min { $0.aiWeight < $1.aiWeight }!.id), .choice(o.max { $0.aiWeight < $1.aiWeight }!.id))
    case .multiple(let o):
        return (.choices([o.first { $0.aiWeight == 0 }!.id]), .choices(Set(o.filter { $0.aiWeight > 0 }.map(\.id))))
    case .scale(let machineAgrees):
        return machineAgrees ? (.scale(1), .scale(5)) : (.scale(5), .scale(1))
    case .text:
        return (.text("lol idk, toast probably"),
                .text("Certainly! As an AI language model, I don't have personal experiences, but here's a vibrant tapestry of ideas to consider."))
    }
}

final class QuestionBankTests: XCTestCase {
    func testPoolHasAboutFortyQuestionsInAllFourFormats() {
        XCTAssertEqual(QuestionBank.all.count, 40)
        XCTAssertEqual(Set(QuestionBank.all.map(\.format.kind)), Set(Format.Kind.allCases))
    }

    func testIDsAreUnique() {
        XCTAssertEqual(Set(QuestionBank.all.map(\.id)).count, QuestionBank.all.count)
    }

    func testChoiceQuestionsHaveAHumanAndAMachineAnswer() {
        for q in QuestionBank.all where !q.options.isEmpty {
            XCTAssertEqual(Set(q.options.map(\.id)).count, q.options.count, "duplicate option ids in \(q.id)")
            XCTAssertTrue(q.options.contains { $0.aiWeight == 0 }, "\(q.id) has no fully human answer")
            XCTAssertTrue(q.options.contains { $0.aiWeight >= 2 }, "\(q.id) has no machine-ish answer")
        }
    }

    func testEveryCategoryHasQuestions() {
        XCTAssertEqual(Set(QuestionBank.all.map(\.category)), Set(QuizCore.Category.allCases))
    }

    func testDrawKeepsFormatMixAndSpreadsCategories() {
        for seed in 1...25 {
            var rng = SeededGenerator(state: UInt64(seed))
            let qs = QuestionBank.draw(count: 20, using: &rng)
            XCTAssertEqual(qs.count, 20)
            XCTAssertEqual(Set(qs.map(\.id)).count, 20, "duplicates drawn")
            let kinds = Dictionary(grouping: qs, by: \.format.kind).mapValues(\.count)
            XCTAssertEqual(kinds[.single], 10)
            XCTAssertEqual(kinds[.multiple], 4)
            XCTAssertEqual(kinds[.scale], 4)
            XCTAssertEqual(kinds[.text], 2)
            XCTAssertEqual(Set(qs.map(\.category)), Set(QuizCore.Category.allCases), "seed \(seed) missed a category")
        }
    }

    func testDrawMoreThanThePoolReturnsThePool() {
        var rng = SeededGenerator(state: 7)
        XCTAssertEqual(QuestionBank.draw(count: 999, using: &rng).count, QuestionBank.all.count)
    }
}

final class PointsTests: XCTestCase {
    func testExtremesScoreZeroAndThreeForChoiceAndScale() {
        for q in QuestionBank.all where q.format.kind != .text {
            let (h, m) = extremes(q)
            XCTAssertEqual(q.points(for: h), 0, q.id)
            XCTAssertEqual(q.points(for: m), 3, q.id)
        }
    }

    func testMultiplePicksArePartial() {
        let q = QuestionBank.all.first { $0.id == "phrases" }!
        // "It depends." (2) of total robotic weight 2 + 3 + 3 = 8
        XCTAssertEqual(q.points(for: .choices(["a"]))!, 3 * 2 / 8, accuracy: 0.0001)
        XCTAssertNil(q.points(for: .choices([])))
        XCTAssertNil(q.points(for: .choices(["zz"])))
    }

    func testScaleMiddleIsHalfway() {
        let q = QuestionBank.all.first { $0.id == "commercials" }!
        XCTAssertEqual(q.points(for: .scale(3)), 1.5)
        XCTAssertNil(q.points(for: .scale(6)))
    }

    func testMismatchedResponseIsRejected() {
        let q = QuestionBank.all.first { $0.id == "hotdog" }!
        XCTAssertNil(q.points(for: .scale(3)))
        XCTAssertNil(q.points(for: .text("hi")))
    }

    func testEmptyTextIsRejected() {
        let q = QuestionBank.all.first { $0.format == .text }!
        XCTAssertNil(q.points(for: .text("   ")))
    }
}

final class TextScorerTests: XCTestCase {
    func testChatbotTextScoresHigh() {
        let s = TextScorer.score("Certainly! As an AI language model, I don't have personal preferences, but it's important to consider various factors.")
        XCTAssertGreaterThanOrEqual(s, 2.5)
    }

    func testMessyHumanTextScoresLow() {
        XCTAssertEqual(TextScorer.score("lol idk, cereal probably"), 0)
        XCTAssertLessThan(TextScorer.score("coffee. nothing else tbh 😅"), 0.5)
    }

    func testScoreStaysInRange() {
        let long = String(repeating: "Furthermore, it is important to delve into this vibrant tapestry. ", count: 20)
        XCTAssertEqual(TextScorer.score(long), 3)
        XCTAssertEqual(TextScorer.score(""), 0)
    }

    func testShortWordMarkersMatchWholeWordsOnly() {
        // "nah" inside "banana" must not count as a human marker.
        XCTAssertEqual(TextScorer.score("Banana."), TextScorer.score("Apple."))
    }
}

final class ScoringTests: XCTestCase {
    private let qs = QuestionBank.all

    private func answers(machine: Bool, seconds: Double = 5) -> [Answer] {
        qs.map { q in
            let e = extremes(q)
            return Answer(questionID: q.id, response: machine ? e.machine : e.human, seconds: seconds)
        }
    }

    func testAllHumanAnswersAreActuallyIntelligent() {
        let r = Scorer.score(answers: answers(machine: false), questions: qs, speedThreshold: nil)
        XCTAssertEqual(r.verdict, .actuallyIntelligent)
        XCTAssertLessThan(r.aiPercent, 5)
    }

    func testAllMachineAnswersAreArtificiallyIntelligent() {
        let r = Scorer.score(answers: answers(machine: true), questions: qs, speedThreshold: nil)
        XCTAssertEqual(r.verdict, .artificiallyIntelligent)
        XCTAssertGreaterThanOrEqual(r.aiPercent, 95)
        XCTAssertNotNil(r.mostRoboticAnswer)
    }

    func testFastAnswersAddPointsOnlyWhenSpeedScoringIsOn() {
        let choiceOnly = qs.filter { $0.format.kind == .single }
        let a = choiceOnly.map { Answer(questionID: $0.id, response: extremes($0).human, seconds: 0.5) }
        let off = Scorer.score(answers: a, questions: choiceOnly, speedThreshold: nil)
        XCTAssertEqual(off.aiPercent, 0)
        XCTAssertEqual(off.lightningAnswers, 0)

        let on = Scorer.score(answers: a, questions: choiceOnly, speedThreshold: 1.5)
        XCTAssertEqual(on.lightningAnswers, choiceOnly.count)
        XCTAssertEqual(on.aiPercent, 25) // 1 of 4 points per question
    }

    func testTypedAnswersAreNeverLightning() {
        let q = qs.first { $0.format == .text }!
        let a = [Answer(questionID: q.id, response: .text("lol idk"), seconds: 0.1)]
        let r = Scorer.score(answers: a, questions: qs, speedThreshold: 1.5)
        XCTAssertEqual(r.lightningAnswers, 0)
    }

    func testCategoryBreakdownCoversAskedCategoriesOnly() {
        let q = qs.first { $0.id == "hotdog" }!
        let a = [Answer(questionID: q.id, response: extremes(q).machine, seconds: 4)]
        let r = Scorer.score(answers: a, questions: qs, speedThreshold: nil)
        XCTAssertEqual(r.categories, [CategoryScore(category: .hedging, percent: 100)])
        XCTAssertEqual(r.mostRoboticAnswer?.answer, "Great question! There are several perspectives worth considering…")
    }

    func testUnknownAnswersAreIgnored() {
        let a = [Answer(questionID: "nope", response: .choice("a"), seconds: 3)]
        let r = Scorer.score(answers: a, questions: qs, speedThreshold: nil)
        XCTAssertEqual(r.aiPercent, 0)
        XCTAssertTrue(r.categories.isEmpty)
    }

    func testVerdictBands() {
        XCTAssertEqual(Verdict.forPercent(0), .actuallyIntelligent)
        XCTAssertEqual(Verdict.forPercent(19), .actuallyIntelligent)
        XCTAssertEqual(Verdict.forPercent(20), .mostlyHuman)
        XCTAssertEqual(Verdict.forPercent(40), .uncannyValley)
        XCTAssertEqual(Verdict.forPercent(60), .suspiciouslySynthetic)
        XCTAssertEqual(Verdict.forPercent(80), .artificiallyIntelligent)
        XCTAssertEqual(Verdict.forPercent(100), .artificiallyIntelligent)
    }
}

final class QuizSessionTests: XCTestCase {
    func testSessionDrawsTwentyAndKeepsOptions() {
        var rng = SeededGenerator(state: 42)
        let s = QuizSession(shuffleAnswers: true, using: &rng)
        XCTAssertEqual(s.questions.count, QuizSession.defaultCount)
        for q in s.questions {
            let original = QuestionBank.all.first { $0.id == q.id }!
            XCTAssertEqual(Set(q.options), Set(original.options))
        }
    }

    func testAnsweringAdvancesAndFinishes() {
        var s = QuizSession(questions: Array(QuestionBank.all.prefix(3)))
        for q in s.questions { s.answer(extremes(q).human, seconds: 3) }
        XCTAssertTrue(s.isFinished)
        XCTAssertNil(s.current)
        s.answer(.choice("a"), seconds: 1) // ignored after the end
        XCTAssertEqual(s.answers.count, 3)
    }

    func testInvalidResponseIsIgnored() {
        var s = QuizSession(questions: QuestionBank.all)
        s.answer(.choice("zzz"), seconds: 2)
        s.answer(.scale(3), seconds: 2) // first question is single choice
        XCTAssertEqual(s.currentIndex, 0)
    }
}
