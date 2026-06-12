import Foundation
import Combine

@MainActor
final class HoldingDetailViewModel: ObservableObject {
    @Published var transactions: [HoldingTransaction] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String?
    @Published var directionFilter: TradeDirectionFilter = .all
    @Published private(set) var totalCount: Int = 0

    let holdingId: Int

    private let appState: AppState
    private let pageSize = 20
    private var page = 1

    var hasMore: Bool { transactions.count < totalCount }

    init(holdingId: Int, appState: AppState = .shared) {
        self.holdingId = holdingId
        self.appState = appState
    }

    func load() async {
        guard let token = appState.accessToken else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response: HoldingTransactionsResponse = try await APIClient.shared.request(
                endpoint: .myHoldingTransactions(
                    holdingId: holdingId,
                    direction: directionFilter.queryValue,
                    page: 1,
                    pageSize: pageSize
                ),
                accessToken: token,
                deviceId: appState.deviceId
            )
            page = 1
            transactions = response.transactions
            totalCount = response.totalCount
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMore() async {
        guard !isLoading, !isLoadingMore, hasMore, let token = appState.accessToken else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let nextPage = page + 1
            let response: HoldingTransactionsResponse = try await APIClient.shared.request(
                endpoint: .myHoldingTransactions(
                    holdingId: holdingId,
                    direction: directionFilter.queryValue,
                    page: nextPage,
                    pageSize: pageSize
                ),
                accessToken: token,
                deviceId: appState.deviceId
            )
            page = nextPage
            transactions.append(contentsOf: response.transactions)
            totalCount = response.totalCount
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
