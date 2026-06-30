import Foundation

@MainActor
final class FalProvider: ProviderRuntime {
    let provider = Provider(
        id: "fal",
        displayName: "Fal.ai",
        icon: .providerMark("fal"),
        links: [
            ProviderLink(label: "Billing", url: "https://fal.ai/dashboard/billing")
        ]
    )

    let authStore: FalAuthStore
    let usageClient: FalUsageClient
    let now: @Sendable () -> Date

    init(
        authStore: FalAuthStore = FalAuthStore(),
        usageClient: FalUsageClient = FalUsageClient(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.authStore = authStore
        self.usageClient = usageClient
        self.now = now
    }

    var widgetDescriptors: [WidgetDescriptor] {
        [
            .dollarBalance(id: "fal.balance", provider: provider, title: "Balance", metricLabel: "Balance", valueWord: "left")
        ]
    }

    func refresh() async -> ProviderSnapshot {
        guard let auth = await loadOffMainActor({ [authStore] in authStore.loadAPIKey() }) else {
            return ProviderSnapshot.error(provider: provider, error: FalAuthError.missingKey)
        }

        let result = await load { try await usageClient.fetchBilling(apiKey: auth.apiKey) }
        
        switch result {
        case .success(let data):
            let lines = FalUsageMapper.billingMetrics(from: data)
            if !lines.isEmpty {
                return ProviderSnapshot.make(provider: provider, plan: nil, lines: lines, refreshedAt: now())
            }
            return ProviderSnapshot.error(provider: provider, error: FalUsageError.invalidResponse)
        case .authFailure:
            return ProviderSnapshot.error(provider: provider, error: FalAuthError.invalidKey)
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
            guard let data = FalUsageMapper.dataObject(response.body) else {
                return .failed(.invalidResponse)
            }
            return .success(data)
        } catch {
            return .failed(.connectionFailed)
        }
    }
}

extension FalProvider: APIKeyManaging {
    var apiKeyStatus: APIKeyStatus { authStore.keyStatus() }
    func currentAPIKey() -> String? { authStore.currentAPIKey() }
    func saveAPIKey(_ key: String) throws { try authStore.saveAPIKey(key) }
    func deleteAPIKey() throws { try authStore.deleteAPIKey() }
    var apiKeyStorageDescription: String { FalAuthStore.configPaths[0] }
    var apiKeyEnvironmentName: String { FalAuthStore.environmentNames[0] }
}

private enum EndpointResult {
    case success([String: Any])
    case authFailure
    case failed(FalUsageError)
}
