import Foundation

struct HiggsfieldAuth: Hashable, Sendable {
    enum Source: Hashable, Sendable {
        case environment
        case configFile
    }

    var apiKey: String
    var source: Source
}

enum HiggsfieldAuthError: Error, LocalizedError, Equatable {
    case missingKey
    case invalidKey
    case saveFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .missingKey:
            return "No Higgsfield.ai API key. Set HIGGSFIELD_API_KEY or add it to ~/.config/openusage/higgsfield.json."
        case .invalidKey:
            return "Higgsfield.ai API key invalid. Check your key in the dashboard."
        case .saveFailed:
            return "Couldn't save the Higgsfield.ai API key."
        case .deleteFailed:
            return "Couldn't remove the saved Higgsfield.ai API key."
        }
    }
}

struct HiggsfieldAuthStore: Sendable {
    static let configPaths = [
        "~/.config/openusage/higgsfield.json",
        "~/.config/higgsfield/key.json"
    ]
    static let environmentNames = ["HIGGSFIELD_API_KEY", "HIGGSFIELD_KEY"]

    var files: TextFileAccessing
    var environment: EnvironmentReading

    init(
        files: TextFileAccessing = LocalTextFileAccessor(),
        environment: EnvironmentReading = ProcessEnvironmentReader()
    ) {
        self.files = files
        self.environment = environment
    }

    func loadAPIKey() -> HiggsfieldAuth? {
        if let key = keyFromConfigFile() {
            return HiggsfieldAuth(apiKey: key, source: .configFile)
        }
        if let key = keyFromEnvironment() {
            return HiggsfieldAuth(apiKey: key, source: .environment)
        }
        return nil
    }

    func currentAPIKey() -> String? {
        loadAPIKey()?.apiKey
    }

    func keyStatus() -> APIKeyStatus {
        let hasConfig = keyFromConfigFile() != nil
        let hasEnv = keyFromEnvironment() != nil
        switch (hasConfig, hasEnv) {
        case (true, true): return .overrideActive
        case (true, false): return .saved
        case (false, true): return .fromEnvironment
        default: return .notSet
        }
    }

    func saveAPIKey(_ key: String) throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw HiggsfieldAuthError.missingKey }
        let data = try JSONSerialization.data(withJSONObject: ["apiKey": trimmed], options: [.sortedKeys])
        guard let text = String(data: data, encoding: .utf8) else { throw HiggsfieldAuthError.saveFailed }
        do {
            try files.writeText(Self.configPaths[0], text)
        } catch {
            AppLog.error(.auth, "save API key to \(Self.configPaths[0]) failed: \(error.localizedDescription)")
            throw HiggsfieldAuthError.saveFailed
        }
    }

    func deleteAPIKey() throws {
        for path in Self.configPaths {
            guard files.exists(path) else { continue }
            do {
                try files.remove(path)
            } catch {
                AppLog.error(.auth, "delete API key at \(path) failed: \(error.localizedDescription)")
                throw HiggsfieldAuthError.deleteFailed
            }
        }
    }

    private func keyFromEnvironment() -> String? {
        for name in Self.environmentNames {
            if let value = environment.value(for: name)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private func keyFromConfigFile() -> String? {
        for path in Self.configPaths {
            guard files.exists(path), let text = try? files.readText(path) else { continue }
            if let key = Self.keyFromConfigText(text) {
                return key
            }
        }
        return nil
    }

    static func keyFromConfigText(_ text: String) -> String? {
        if let data = text.data(using: .utf8),
           let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
            for field in ["apiKey", "api_key", "key"] {
                if let value = (object[field] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !value.isEmpty {
                    return value
                }
            }
            return nil
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed.contains("{") ? nil : trimmed
    }
}
