import SwiftUI

/// UserDefaults keys and defaults for every preference, so Settings and the quiz agree.
public enum PrefKey {
    public static let shuffleAnswers = "shuffleAnswers"
    public static let speedScoring = "speedScoring"
    public static let appearance = "appearance"
}

/// True only in the offline screenshot renderer, which can't draw live text fields.
private struct StaticRenderKey: EnvironmentKey { static let defaultValue = false }

public extension EnvironmentValues {
    var isStaticRender: Bool {
        get { self[StaticRenderKey.self] }
        set { self[StaticRenderKey.self] = newValue }
    }
}

public enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .system: "Match System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
