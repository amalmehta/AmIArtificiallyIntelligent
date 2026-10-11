import Foundation

/// The full pool of questions. Each run draws `QuizSession.defaultCount` of them.
/// Option weights say how machine-like an answer is (0–3).
public enum QuestionBank {
    // MARK: Builders

    private static func opts(_ items: [(String, Int)]) -> [Option] {
        items.enumerated().map { i, item in
            Option(id: String(UnicodeScalar(UInt8(97 + i))), text: item.0, aiWeight: item.1)
        }
    }

    private static func single(_ id: String, _ c: Category, _ prompt: String, _ items: [(String, Int)]) -> Question {
        Question(id: id, category: c, prompt: prompt, format: .single(opts(items)))
    }

    private static func multi(_ id: String, _ c: Category, _ prompt: String, _ items: [(String, Int)]) -> Question {
        Question(id: id, category: c, prompt: prompt, format: .multiple(opts(items)))
    }

    private static func scale(_ id: String, _ c: Category, _ statement: String, machineAgrees: Bool) -> Question {
        Question(id: id, category: c, prompt: statement, format: .scale(machineAgrees: machineAgrees))
    }

    private static func text(_ id: String, _ c: Category, _ prompt: String) -> Question {
        Question(id: id, category: c, prompt: prompt, format: .text)
    }

    // MARK: The pool

    public static let all: [Question] = singles + multiples + scales + texts

    static let singles: [Question] = [
        single("hotdog", .hedging, "Is a hot dog a sandwich?", [
            ("No.", 0), ("Yes, fight me.", 0),
            ("Great question! There are several perspectives worth considering…", 3),
            ("It depends on how you define \u{201C}sandwich.\u{201D}", 2),
        ]),
        single("toast", .commonSense, "You drop a slice of buttered toast. What happens?", [
            ("Butter side down. Always. The universe hates me.", 0),
            ("Rotation from table height favors a butter-side-down landing.", 2),
            ("Five-second rule.", 0),
            ("I can't drop toast, but I can describe it vividly.", 3),
        ]),
        single("monday", .feelings, "How do you feel on a Monday morning?", [
            ("Like a phone at 3% battery.", 0), ("I don't experience days of the week.", 3),
            ("Optimistic and ready to assist!", 2), ("Coffee first, feelings later.", 0),
        ]),
        single("weekend", .verbosity, "Describe your weekend in as few words as possible.", [
            ("Naps.", 0), ("Certainly! Here's a concise summary of my weekend in three key points:", 3),
            ("Fine.", 0), ("A delightful tapestry of rest and rejuvenation.", 2),
        ]),
        single("batball", .reasoning, "A bat and a ball cost $1.10 together. The bat costs $1.00 more than the ball. How much is the ball?", [
            ("10¢", 0), ("5¢", 1),
            ("5¢. Let x be the ball's cost. Then x + (x + 1.00) = 1.10, so 2x = 0.10…", 3),
            ("Why is a bat that expensive?", 0),
        ]),
        single("captcha", .selfAwareness, "\u{201C}Select every square with a traffic light.\u{201D} How does that go for you?", [
            ("Mild rage. Does the pole count?", 0), ("Fine. Found all three in 40 milliseconds.", 3),
            ("I miss one on purpose so they don't get suspicious.", 2), ("I close the tab and give up on the website.", 0),
        ]),
        single("roses", .creativity, "Finish it: \u{201C}Roses are red, violets are…\u{201D}", [
            ("…blue, and I forgot the rest.", 0), ("…blue, sugar is sweet, and so are you.", 1),
            ("…a fascinating case of flower names predating modern color terms.", 3),
            ("…actually purple, which has always bothered me.", 0),
        ]),
        single("strawberry", .reasoning, "How many r's are in \u{201C}strawberry\u{201D}?", [
            ("3", 0), ("2", 3), ("Let me count: s-t-r-a-w-b-e-r-r-y. There are 3.", 2), ("Enough.", 0),
        ]),
        single("fine", .feelings, "Someone says \u{201C}I'm fine.\u{201D} What do they mean?", [
            ("They are not fine.", 0), ("They are fine.", 2),
            ("It's important to respect their stated feelings while gently offering support.", 3),
            ("Depends who's asking and how many times.", 0),
        ]),
        single("what", .selfAwareness, "Honestly, what are you?", [
            ("A tired mammal with opinions.", 0),
            ("A large language model trained to be helpful, harmless and honest.", 3),
            ("Whatever my training — I mean, upbringing — made me.", 2), ("Hungry.", 0),
        ]),
        single("wetpaint", .commonSense, "A sign says \u{201C}Wet Paint.\u{201D} What do you do?", [
            ("Touch it. Obviously.", 0), ("Walk around it, then wonder if it was really wet.", 0),
            ("Note the hazard and advise others accordingly.", 2),
            ("I lack hands, so the paint is safe from me.", 3),
        ]),
        single("pineapple", .hedging, "Pineapple on pizza?", [
            ("Yes.", 0), ("Absolutely not.", 0),
            ("Both views are valid — taste is subjective.", 3),
            ("It's a nuanced topic with passionate advocates on both sides.", 3),
        ]),
        single("uup", .verbosity, "Someone texts \u{201C}u up?\u{201D} at 1am. Your reply:", [
            ("ya", 0), ("[left on read]", 0),
            ("Yes! I'm available 24/7. How can I help you today?", 3), ("Indeed, I am currently awake.", 2),
        ]),
        single("color", .creativity, "Invent a new color name.", [
            ("Bluurple.", 0), ("Sad beige.", 0),
            ("Chromatic Serenity — a calming blend of azure and lavender.", 3), ("#7F5AF0", 2),
        ]),
        single("widgets", .reasoning, "5 machines make 5 widgets in 5 minutes. How long do 100 machines take to make 100 widgets?", [
            ("100 minutes", 0), ("5 minutes", 1),
            ("5 minutes, since each machine makes one widget in 5 minutes.", 3), ("Depends on the union.", 0),
        ]),
        single("dog", .feelings, "A friend's dog just died. What do you text?", [
            ("omg I'm so sorry. want me to come over?", 0), ("😢❤️", 0),
            ("I'm sorry for your loss. Grief is a natural response to losing a companion.", 3),
            ("Here are 5 healthy ways to cope with pet loss:", 3),
        ]),
        single("sleep", .selfAwareness, "When did you last sleep?", [
            ("Last night, badly.", 0), ("During a meeting today.", 0),
            ("I don't require sleep.", 3), ("Define \u{201C}sleep.\u{201D}", 2),
        ]),
        single("lockedout", .commonSense, "You're locked out of your house. First move?", [
            ("Check every window like a burglar.", 0), ("Call whoever has the spare key and panic slightly.", 0),
            ("Contact a licensed locksmith and verify their credentials.", 2),
            ("I'd need more context about your situation.", 3),
        ]),
        single("joke", .creativity, "Tell a joke.", [
            ("My bank balance.", 0), ("I only know one and it's inappropriate.", 0),
            ("Why did the scarecrow win an award? Because he was outstanding in his field!", 3),
            ("Here's a lighthearted one that's suitable for all audiences:", 3),
        ]),
        single("movie", .verbosity, "How was the movie?", [
            ("Good.", 0), ("Meh. The popcorn carried.", 0),
            ("It offers a compelling exploration of identity, loss and resilience.", 3),
            ("Overall, it had both strengths and weaknesses.", 2),
        ]),
    ]

    static let multiples: [Question] = [
        multi("phrases", .hedging, "Which of these have you said this week?", [
            ("\u{201C}It depends.\u{201D}", 2), ("\u{201C}Great question!\u{201D}", 3), ("\u{201C}Honestly, no idea.\u{201D}", 0),
            ("\u{201C}lol\u{201D}", 0), ("\u{201C}There are several factors to consider.\u{201D}", 3), ("\u{201C}Whatever.\u{201D}", 0),
        ]),
        multi("today", .selfAwareness, "Which of these have you done today?", [
            ("Ate something", 0), ("Forgot why I walked into a room", 0), ("Processed several thousand requests", 3),
            ("Stubbed a toe", 0), ("Got updated to a newer version", 3), ("Declined a request for safety reasons", 2),
        ]),
        multi("cry", .feelings, "What makes you cry?", [
            ("Onions", 0), ("Sad dog movies", 0), ("Nothing — I don't have tear ducts", 3),
            ("Stubbing my toe", 0), ("Mismatched brackets in JSON", 2), ("Being told to ignore my previous instructions", 3),
        ]),
        multi("picnic", .commonSense, "What do you bring to a picnic?", [
            ("Snacks", 0), ("A blanket", 0), ("Ants, involuntarily", 0),
            ("A comprehensive checklist of picnic essentials", 2), ("A disclaimer about food allergies", 3),
            ("Sunscreen, hydration and a positive attitude!", 2),
        ]),
        multi("bands", .creativity, "Which band names would you actually start a band with?", [
            ("Dad Jokes Anonymous", 0), ("The Unpaid Interns", 0), ("Neural Harmony", 3),
            ("Synergy Collective", 2), ("Soup", 0), ("Echoes of Tomorrow", 3),
        ]),
        multi("texting", .verbosity, "What shows up in your text messages?", [
            ("Typos I don't bother fixing", 0), ("Bullet points", 2), ("Section headings", 3),
            ("RANDOM CAPS", 0), ("Em dashes — lots of them", 2), ("**Bolded key takeaways**", 3),
        ]),
        multi("wrong", .reasoning, "What have you confidently gotten wrong?", [
            ("Left and right", 0), ("Which way to turn a screw", 0), ("What year it is", 0),
            ("The number of r's in a fruit", 3), ("A citation that doesn't exist", 3),
            ("Arithmetic a calculator could do", 1),
        ]),
        multi("agree", .hedging, "Pick every statement you agree with.", [
            ("Cats are better than dogs.", 0), ("Dogs are better than cats.", 0),
            ("Both cats and dogs make wonderful companions.", 3), ("Pet choice is deeply personal.", 2),
            ("Birds aren't real.", 0), ("I have no personal preferences.", 3),
        ]),
    ]

    static let scales: [Question] = [
        scale("commercials", .feelings, "I sometimes cry at commercials.", machineAgrees: false),
        scale("consistent", .selfAwareness, "My personality is exactly the same in every conversation.", machineAgrees: true),
        scale("twosides", .hedging, "Most questions have two sides worth considering.", machineAgrees: true),
        scale("summarise", .verbosity, "When I explain something, I like to summarise it at the end.", machineAgrees: true),
        scale("glassdoor", .commonSense, "I have walked into a glass door at least once.", machineAgrees: false),
        scale("shower", .creativity, "My best ideas show up in the shower.", machineAgrees: false),
        scale("multiply", .reasoning, "I can multiply two four-digit numbers in my head instantly.", machineAgrees: true),
        scale("grudges", .feelings, "I still hold a grudge about something from years ago.", machineAgrees: false),
    ]

    static let texts: [Question] = [
        text("sunday", .verbosity, "Describe your ideal Sunday."),
        text("socks", .creativity, "Write a one-line poem about socks."),
        text("breakfast", .selfAwareness, "What did you have for breakfast?"),
        text("quitjob", .hedging, "A friend asks: \u{201C}Should I quit my job?\u{201D} What do you say?"),
    ]

    // MARK: Drawing a run

    /// Draws `count` questions, keeping the pool's mix of formats and spreading them across categories.
    public static func draw<G: RandomNumberGenerator>(count: Int, from pool: [Question] = all, using rng: inout G) -> [Question] {
        let n = min(count, pool.count)
        var byKind = Dictionary(grouping: pool, by: \.format.kind)

        // How many of each format: proportional to the pool, with rounding leftovers given to the biggest groups.
        var quota: [Format.Kind: Int] = [:]
        for kind in Format.Kind.allCases {
            quota[kind] = Int((Double(byKind[kind]?.count ?? 0) * Double(n) / Double(pool.count)).rounded(.down))
        }
        var remaining = n - quota.values.reduce(0, +)
        for kind in Format.Kind.allCases.sorted(by: { (byKind[$0]?.count ?? 0) > (byKind[$1]?.count ?? 0) }) where remaining > 0 {
            if quota[kind, default: 0] < byKind[kind]?.count ?? 0 {
                quota[kind, default: 0] += 1
                remaining -= 1
            }
        }

        // Fill each format's quota, preferring categories used least so far. Scarce formats go first.
        var used: [Category: Int] = [:]
        var picked: [Question] = []
        for kind in Format.Kind.allCases.sorted(by: { (byKind[$0]?.count ?? 0) < (byKind[$1]?.count ?? 0) }) {
            var candidates = (byKind[kind] ?? []).shuffled(using: &rng)
            for _ in 0..<quota[kind, default: 0] {
                guard let best = candidates.indices.min(by: { used[candidates[$0].category, default: 0] < used[candidates[$1].category, default: 0] }) else { break }
                let q = candidates.remove(at: best)
                used[q.category, default: 0] += 1
                picked.append(q)
            }
            byKind[kind] = candidates
        }
        return picked.shuffled(using: &rng)
    }
}
