import Foundation

// Unified grouped portfolio (GET /api/v3/me/portfolio, §48.1).
struct PortfolioResponse: Decodable {
    let portfolioId: String?
    let ownerType: String?
    let ownerName: String?
    let totalValueRsd: String?
    let totalProfitRsd: String?
    let totalProfitPct: String?
    let securities: PortfolioGroup<SecurityPosition>?
    let funds: PortfolioGroup<FundPosition>?
}

struct PortfolioGroup<Position: Decodable>: Decodable {
    let totalValueRsd: String?
    let totalProfitRsd: String?
    let totalProfitPct: String?
    let positions: [Position]?
}

struct SecurityPosition: Decodable, Identifiable {
    let assetType: String
    let symbol: String
    let holdingId: Int
    let quantity: Int
    let avgCostRsd: String?
    let currentPriceRsd: String?
    let currentValueRsd: String?
    let profitLossRsd: String?
    let profitLossPct: String?
    let dividendsReceivedRsd: String?
    let lastUpdated: String?

    var id: Int { holdingId }

    // The decoder converts snake_case before matching, so "p_l_rsd" arrives as "pLRsd".
    enum CodingKeys: String, CodingKey {
        case assetType, symbol, holdingId, quantity
        case avgCostRsd, currentPriceRsd, currentValueRsd
        case profitLossRsd = "pLRsd"
        case profitLossPct = "pLPct"
        case dividendsReceivedRsd, lastUpdated
    }
}

struct FundPosition: Decodable, Identifiable {
    let assetType: String?
    let fundId: Int
    let fundName: String
    let amountInvestedRsd: String?
    let currentValueRsd: String?
    let pctOfFund: String?
    let profitLossRsd: String?
    let profitLossPct: String?
    let dividendsReceivedRsd: String?
    let fundStatus: String?
    let lastUpdated: String?

    var id: Int { fundId }

    enum CodingKeys: String, CodingKey {
        case assetType, fundId, fundName
        case amountInvestedRsd, currentValueRsd, pctOfFund
        case profitLossRsd = "pLRsd"
        case profitLossPct = "pLPct"
        case dividendsReceivedRsd, fundStatus, lastUpdated
    }
}

// Per-trade breakdown of a holding (GET /api/v3/me/holdings/{id}/transactions).
struct HoldingTransaction: Decodable, Identifiable {
    let id: Int
    let orderId: Int?
    let executedAt: String?
    let direction: String
    let quantity: Int
    let pricePerUnit: String?
    let nativeAmount: String?
    let nativeCurrency: String?
    let convertedAmount: String?
    let accountCurrency: String?
    let fxRate: String?
    let commission: String?
    let accountId: Int?
    let ticker: String?

    var isBuy: Bool { direction.lowercased() == "buy" }
}

struct HoldingTransactionsResponse: Decodable {
    let transactions: [HoldingTransaction]
    let totalCount: Int
}

enum TradeDirectionFilter: String, CaseIterable, Identifiable {
    case all
    case buy
    case sell

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All"
        case .buy: return "Buys"
        case .sell: return "Sells"
        }
    }

    var queryValue: String? {
        self == .all ? nil : rawValue
    }
}

// Summary endpoint (GET /api/v3/me/portfolio/summary). The doc does not pin the
// object's shape, so every field is optional and unknown keys are ignored.
struct PortfolioSummary: Decodable {
    let totalValue: String?
    let totalCost: String?
    let totalProfitLoss: String?
    let totalProfitLossPercent: String?
    let holdingsCount: Int?
}

// Display helpers for the API's decimal strings (e.g. "11000.0000").
enum RSDFormat {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    static func amount(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        guard let value = Decimal(string: raw) else { return raw }
        return formatter.string(from: value as NSDecimalNumber) ?? raw
    }

    static func money(_ raw: String?) -> String? {
        amount(raw).map { "\($0) RSD" }
    }

    static func signedMoney(_ raw: String?) -> String? {
        guard let formatted = money(raw) else { return nil }
        return formatted.hasPrefix("-") ? formatted : "+\(formatted)"
    }

    static func signedPercent(_ raw: String?) -> String? {
        guard let formatted = amount(raw) else { return nil }
        return formatted.hasPrefix("-") ? "\(formatted)%" : "+\(formatted)%"
    }

    static func percent(_ raw: String?) -> String? {
        amount(raw).map { "\($0)%" }
    }

    static func isLoss(_ raw: String?) -> Bool {
        raw?.hasPrefix("-") ?? false
    }

    static func isZero(_ raw: String?) -> Bool {
        guard let raw, let value = Decimal(string: raw) else { return true }
        return value == 0
    }

    static func date(_ iso: String?) -> Date? {
        guard let iso else { return nil }
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: iso) { return date }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: iso)
    }
}
