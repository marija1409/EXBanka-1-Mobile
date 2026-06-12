import Foundation
import Combine

@MainActor
final class PortfolioViewModel: ObservableObject {
    @Published var portfolio: PortfolioResponse?
    @Published var summary: PortfolioSummary?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let appState: AppState

    init(appState: AppState = .shared) {
        self.appState = appState
    }

    var securityPositions: [SecurityPosition] {
        portfolio?.securities?.positions ?? []
    }

    var fundPositions: [FundPosition] {
        portfolio?.funds?.positions ?? []
    }

    var isEmpty: Bool {
        securityPositions.isEmpty && fundPositions.isEmpty
    }

    func load() async {
        guard let token = appState.accessToken else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let portfolioReq: PortfolioResponse = APIClient.shared.request(
                endpoint: .myPortfolio,
                accessToken: token,
                deviceId: appState.deviceId
            )
            // The summary object's shape is not pinned by the v3 doc, so it is
            // fetched best-effort and only adds detail when fields are present.
            async let summaryReq: PortfolioSummary = APIClient.shared.request(
                endpoint: .myPortfolioSummary,
                accessToken: token,
                deviceId: appState.deviceId
            )
            self.portfolio = try await portfolioReq
            self.summary = try? await summaryReq
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
