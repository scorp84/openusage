import Foundation

@MainActor
final class HiggsfieldProvider: ProviderRuntime {
    let provider = Provider(
        id: "higgsfield",
        displayName: "Higgsfield",
        icon: .providerMark("higgsfield"),
        links: [
            ProviderLink(label: "Dashboard", url: "https://cloud.higgsfield.ai")
        ]
    )

    let authStore: HiggsfieldAuthStore
    let usageClient: HiggsfieldUsageClient
    let now: @Sendable () -> Date

    init(
        authStore: HiggsfieldAuthStore = HiggsfieldAuthStore(),
        usageClient: HiggsfieldUsageClient = HiggsfieldUsageClient(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.authStore = authStore
        self.usageClient = usageClient
        self.now = now
    }

    var widgetDescriptors: [WidgetDescriptor] {
        [
            .dollarBalance(id: "higgsfield.balance", provider: provider, title: "Balance", metricLabel: "Balance", valueWord: "left")
        ]
    }

    func refresh() async -> ProviderSnapshot {
        guard let auth = await loadOffMainActor({ [authStore] in authStore.loadAPIKey() }) else {
            return ProviderSnapshot.error(provider: provider, error: HiggsfieldAuthError.missingKey)
        }

        let result = await load { try await usageClient.fetchBalance(apiKey: auth.apiKey) }
        
        switch result {
        case .success(let data):
            let lines = HiggsfieldUsageMapper.balanceMetrics(from: data)
            if !lines.isEmpty {
                return ProviderSnapshot.make(provider: provider, plan: nil, lines: lines, refreshedAt: now())
            }
            return ProviderSnapshot.error(provider: provider, error: HiggsfieldUsageError.invalidResponse)
        case .authFailure:
            return ProviderSnapshot.error(provider: provider, error: HiggsfieldAuthError.invalidKey)
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
            guard let data = HiggsfieldUsageMapper.dataObject(response.body) else {
                return .failed(.invalidResponse)
            }
            return .success(data)
        } catch {
            return .failed(.connectionFailed)
        }
    }
}

extension HiggsfieldProvider: APIKeyManaging {
    var apiKeyStatus: APIKeyStatus { authStore.keyStatus() }
    func currentAPIKey() -> String? { authStore.currentAPIKey() }
    func saveAPIKey(_ key: String) throws { try authStore.saveAPIKey(key) }
    func deleteAPIKey() throws { try authStore.deleteAPIKey() }
    var apiKeyStorageDescription: String { HiggsfieldAuthStore.configPaths[0] }
    var apiKeyEnvironmentName: String { HiggsfieldAuthStore.environmentNames[0] }
}

private enum EndpointResult {
    case success([String: Any])
    case authFailure
    case failed(HiggsfieldUsageError)
}
