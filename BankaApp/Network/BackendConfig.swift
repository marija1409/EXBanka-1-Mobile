import Foundation
import Combine

private enum BackendDefaults {
    static let storageKey = "backendBaseURL"
    static let baseURL = "https://project-exbanka.bytenity.com/instance1"
}

@MainActor
final class BackendConfig: ObservableObject {
    struct Preset: Identifiable, Hashable {
        let name: String
        let url: String
        var id: String { url }
    }

    static let shared = BackendConfig()

    static let presets: [Preset] = [
        Preset(name: "Instance 1", url: "https://project-exbanka.bytenity.com/instance1"),
        Preset(name: "Localhost", url: "http://localhost:8080"),
    ]

    @Published private(set) var baseURL: String

    private init() {
        baseURL = UserDefaults.standard.string(forKey: BackendDefaults.storageKey) ?? BackendDefaults.baseURL
    }

    // Read by the networking layer, which runs off the main actor.
    nonisolated static var currentBaseURL: String {
        UserDefaults.standard.string(forKey: BackendDefaults.storageKey) ?? BackendDefaults.baseURL
    }

    @discardableResult
    func select(_ urlString: String) -> Bool {
        guard let normalized = Self.normalize(urlString) else { return false }
        UserDefaults.standard.set(normalized, forKey: BackendDefaults.storageKey)
        baseURL = normalized
        return true
    }

    static func normalize(_ urlString: String) -> String? {
        var trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        while trimmed.hasSuffix("/") { trimmed.removeLast() }
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host != nil else {
            return nil
        }
        return trimmed
    }

    var displayName: String {
        baseURL
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
    }
}
