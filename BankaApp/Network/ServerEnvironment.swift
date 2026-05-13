import Foundation

enum ServerEnvironment: String, CaseIterable, Identifiable {
    case localhost  = "http://localhost:8080/api/v3"
    case instance1  = "https://project-exbanka.bytenity.com/instance1/api/v3"
    case instance2  = "https://project-exbanka.bytenity.com/instance2/api/v3"
    case instance3  = "https://project-exbanka.bytenity.com/instance3/api/v3"
    case custom     = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .localhost: return "Localhost"
        case .instance1: return "Bytenity Instance 1"
        case .instance2: return "Bytenity Instance 2"
        case .instance3: return "Bytenity Instance 3"
        case .custom:    return "Custom"
        }
    }

    var baseURL: String {
        if case .custom = self {
            return UserDefaults.standard.string(forKey: Self.customURLKey) ?? ""
        }
        return rawValue
    }

    static let storageKey   = "serverEnvironment"
    static let customURLKey = "serverEnvironmentCustomURL"

    static var current: ServerEnvironment {
        get {
            let saved = UserDefaults.standard.string(forKey: storageKey) ?? ""
            return ServerEnvironment(rawValue: saved) ?? .instance1
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
        }
    }
}
