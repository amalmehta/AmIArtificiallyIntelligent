# Instructions

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15+ or the Swift 5.10+ toolchain (`swift --version`)

## Build the app

```bash
./scripts/build-app.sh
```

This makes `build/Am I Artificially Intelligent.app` (release build, ad-hoc signed). Open it:

```bash
open "build/Am I Artificially Intelligent.app"
```

Drag it into `/Applications` if you want to keep it. Because it's ad-hoc signed, another Mac may need right-click → Open the first time.

For a quick debug run without bundling:

```bash
swift run AmIArtificiallyIntelligent
```

## Run the tests

```bash
swift test
```

## Regenerate the README screenshots

```bash
swift run ScreenshotRenderer docs/images
```

Renders the real views offline, in light and dark mode, with a fixed set of answers.

## Using it

1. **Start the Test.** Each run draws 20 questions from a pool of 40, so repeat runs differ.
2. Answer in four formats:
   - **Pick One**: click an answer or press 1–4.
   - **Pick All That Apply**: tick with a click or 1–6, then Continue (Return).
   - **Agree or Disagree**: click or press 1–5.
   - **In Your Own Words**: type, then Return or Continue.
3. **Your verdict**: a 0–100% "machine" meter, one of five verdicts, a per-category breakdown and your most robotic answer.

### Settings (⌘, or the gear button)

| Setting | Default | What it does |
|---|---|---|
| Shuffle answer order | On | Shuffles options within each choice question |
| Count lightning-fast answers as a robot tell | On | Clicked answers under 1.5 s add a point. Typed answers never count. |
| Theme | Match System | Light, Dark or Match System |

### Feedback

The small **Feedback** pill in the bottom-right corner saves a note to
`~/Library/Application Support/Am I Artificially Intelligent/feedback.jsonl`. Nothing is sent anywhere.
Settings → *Show Feedback File in Finder* opens it.
