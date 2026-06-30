import Foundation

@MainActor
final class MagnificProvider: ProviderRuntime {
    let provider = Provider(
        id: "magnific",
        displayName: "Magnific",
        icon: .providerMark("magnific"),
        links: [
            ProviderLink(label: "Dashboard", url: "https://magnific.ai")
        ]
    )

    let authStore: MagnificAuthStore
    let usageClient: MagnificUsageClient
    let now: @Sendable () -> Date

    init(
        authStore: MagnificAuthStore = MagnificAuthStore(),
        usageClient: MagnificUsageClient = MagnificUsageClient(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.authStore = authStore
        self.usageClient = usageClient
        self.now = now
    }

    var widgetDescriptors: [WidgetDescriptor] {
        [
            .values(id: "magnific.used", provider: provider, title: "Used", metricLabel: "Used", selection: .any, isUsagePeriod: false)
        ]
    }

    func refresh() async -> ProviderSnapshot {
        guard let auth = await loadOffMainActor({ [authStore] in authStore.loadAPIKey() }) else {
            return ProviderSnapshot.error(provider: provider, error: MagnificAuthError.missingKey)
        }

        let result = await load { try await usageClient.fetchTeamCreditUsage(apiKey: auth.apiKey) }
        
        switch result {
        case .success(let data):
            let lines = MagnificUsageMapper.usageMetrics(from: data)
            if !lines.isEmpty {
                return ProviderSnapshot.make(provider: provider, plan: nil, lines: lines, refreshedAt: now())
            }
            return ProviderSnapshot.error(provider: provider, error: MagnificUsageError.invalidResponse)
        case .authFailure:
            return ProviderSnapshot.error(provider: provider, error: MagnificAuthError.invalidKey)
        case .failed(let error):
            return ProviderSnapshot.error(provider: provider, error: error)
        }
    }

    private func load(_ call: () async throws -> HTTPResponse) async -> EndpointResult {
        do {
            let response = try await call()
            if response.statusCode == 401 || response.statusCode == 403 { return .authFailure }
            guard (200..<300).contains(response.statusCode) else {
                return .failed(.requestFailed(response.statusCode))
            }
            guard let data = MagnificUsageMapper.dataObject(response.body) else {
                return .failed(.invalidResponse)
            }
            return .success(data)
        } catch {
            return .failed(.connectionFailed)
        }
    }
}

extension MagnificProvider: APIKeyManaging {
    var apiKeyStatus: APIKeyStatus { authStore.keyStatus() }
    func currentAPIKey() -> String? { authStore.currentAPIKey() }
    func saveAPIKey(_ key: String) throws { try authStore.saveAPIKey(key) }
    func deleteAPIKey() throws { try authStore.deleteAPIKey() }
    var apiKeyStorageDescription: String { MagnificAuthStore.configPaths[0] }
    var apiKeyEnvironmentName: String { MagnificAuthStore.environmentNames[0] }
}

private enum EndpointResult {
    case success([String: Any])
    case authFailure
    case failed(MagnificUsageError)
}
