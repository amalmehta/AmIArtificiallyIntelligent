import Foundation

/// Scores a free-text answer 0–3 for how machine-written it sounds, using simple local heuristics.
public enum TextScorer {
    /// Phrases that sound like a chatbot. Each match adds a point (up to 2).
    static let roboticPhrases = [
        "as an ai", "language model", "great question", "certainly", "i don't have personal", "i do not have",
        "it depends", "it's important to", "it is important to", "delve", "tapestry", "furthermore",
        "additionally", "in conclusion", "overall,", "here's a", "here is a", "i hope this helps", "feel free",
        "ultimately", "various", "factors", "embark", "journey", "vibrant", "a balance", "consider",
        "self-care", "well-being", "rejuvenat", "personal growth", "it's worth noting",
    ]

    /// Markers of a real, untidy human. Each match removes a point (up to 2).
    static let humanMarkers = [
        "lol", "lmao", "idk", "tbh", "ngl", "nah", "ugh", "haha", "dunno", "gonna", "wanna", "kinda",
        "!!", "??", "...", "omg", "meh", "bruh", "smh",
    ]

    public static func score(_ raw: String) -> Double {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return 0 }
        let lower = text.lowercased()
        let words = lower.split(whereSeparator: { !$0.isLetter && $0 != "'" })
        let wordSet = Set(words.map(String.init))

        var score = 0.5

        let robotic = roboticPhrases.filter { lower.contains($0) }.count
        score += Double(min(robotic, 2))

        if words.count > 40 { score += 1 }
        if words.count > 80 { score += 0.5 }

        // Capitalised, punctuated, tidy.
        if let first = text.first, first.isUppercase, let last = text.last, ".!".contains(last) {
            score += 0.5
        }

        let human = humanMarkers.filter { marker in
            marker.allSatisfy(\.isLetter) ? wordSet.contains(marker) : lower.contains(marker)
        }.count
        score -= Double(min(human, 2))

        if text.unicodeScalars.contains(where: { $0.properties.isEmojiPresentation }) { score -= 0.5 }
        if let first = text.first, first.isLowercase { score -= 0.5 }

        return min(max(score, 0), Question.maxPoints)
    }
}
