import Foundation

enum L10n {
    static let language: String = {
        if let forced = ProcessInfo.processInfo.environment["CODEXBAR_LANGUAGE"], ["en", "zh-Hans"].contains(forced) { return forced }
        return Bundle.preferredLocalizations(from: ["en", "zh-Hans"], forPreferences: Locale.preferredLanguages).first ?? "en"
    }()
    static let strings: Bundle? = {
        guard let executable = Bundle.main.executableURL else { return nil }
        let resources = executable.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Resources")
        return Bundle(path: resources.appendingPathComponent("\(language).lproj").path)
    }()
    static func text(_ key: String) -> String {
        strings?.localizedString(forKey: key, value: key, table: nil) ?? key
    }
}
