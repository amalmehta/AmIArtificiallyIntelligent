<img src="docs/images/icon.png" width="128" alt="App icon: half human head, half computer chip">

# Am I Artificially Intelligent?

A Mac app with a playful 20-question quiz that decides whether you're **Actually Intelligent** or **Artificially Intelligent**.

| Start | Pick all that apply | Agree or disagree | Your verdict |
|---|---|---|---|
| ![Welcome screen](docs/images/welcome-light.png) | ![A pick-all-that-apply question](docs/images/question-multiple-light.png) | ![An agree-or-disagree question](docs/images/question-scale-dark.png) | ![Verdict with category breakdown](docs/images/result-light.png) |

```mermaid
flowchart LR
    Pool["40-question pool"] -->|draw 20| Run["Your run"]
    Run --> Score["Score each answer 0–3<br/>(+1 if suspiciously fast)"]
    Score --> Verdict["0–100% machine → verdict"]
```

- [How to build, run and use it](docs/INSTRUCTIONS.md)
- [System design](docs/SYSTEM-DESIGN.md)
- [What's where](docs/FILE-STRUCTURE.md)
