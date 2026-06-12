import SwiftUI

struct PortfolioView: View {
    @StateObject private var viewModel = PortfolioViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if viewModel.isLoading && viewModel.portfolio == nil {
                ProgressView()
            } else if let error = viewModel.errorMessage, viewModel.portfolio == nil {
                VStack(spacing: AppTheme.padding) {
                    Text(error).font(.caption).foregroundColor(.appDestructive)
                    Button("Retry") { Task { await viewModel.load() } }
                        .foregroundColor(.appPrimary)
                }
            } else if let portfolio = viewModel.portfolio {
                ScrollView {
                    VStack(spacing: AppTheme.padding) {
                        PortfolioTotalsCard(portfolio: portfolio, summary: viewModel.summary)

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.appDestructive)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if viewModel.isEmpty {
                            Text("No holdings yet.")
                                .font(.subheadline)
                                .foregroundColor(.appMutedForeground)
                                .padding()
                        }

                        if !viewModel.securityPositions.isEmpty, let group = portfolio.securities {
                            PortfolioSectionHeader(title: "Securities", group: group)
                            ForEach(viewModel.securityPositions) { position in
                                NavigationLink(destination: HoldingDetailView(position: position)) {
                                    SecurityPositionRow(position: position)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if !viewModel.fundPositions.isEmpty, let group = portfolio.funds {
                            PortfolioSectionHeader(title: "Investment Funds", group: group)
                            ForEach(viewModel.fundPositions) { position in
                                FundPositionRow(position: position)
                            }
                        }
                    }
                    .padding(AppTheme.padding)
                }
                .refreshable { await viewModel.load() }
            }
        }
        .navigationTitle("Portfolio")
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.load() }
    }
}

struct PortfolioTotalsCard: View {
    let portfolio: PortfolioResponse
    var summary: PortfolioSummary?

    var body: some View {
        VStack(spacing: AppTheme.smallPadding) {
            if let value = RSDFormat.money(portfolio.totalValueRsd) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.appForeground)
                Text(portfolio.ownerType == "bank" ? "Bank Portfolio Value" : "Total Value")
                    .font(.caption)
                    .foregroundColor(.appMutedForeground)
            }

            if let profit = RSDFormat.signedMoney(portfolio.totalProfitRsd) {
                HStack(spacing: 4) {
                    Text(profit)
                        .font(.system(size: 16, weight: .semibold))
                    if let pct = RSDFormat.signedPercent(portfolio.totalProfitPct) {
                        Text("(\(pct))")
                            .font(.system(size: 14))
                    }
                }
                .foregroundColor(RSDFormat.isLoss(portfolio.totalProfitRsd) ? .appDestructive : .green)
                Text("Total P/L")
                    .font(.caption2)
                    .foregroundColor(.appMutedForeground)
            }

            if let cost = RSDFormat.money(summary?.totalCost) {
                HStack(spacing: AppTheme.largePadding) {
                    VStack(spacing: 2) {
                        Text(cost)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appForeground)
                        Text("Total Cost")
                            .font(.caption2)
                            .foregroundColor(.appMutedForeground)
                    }
                    if let count = summary?.holdingsCount {
                        VStack(spacing: 2) {
                            Text("\(count)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.appForeground)
                            Text("Holdings")
                                .font(.caption2)
                                .foregroundColor(.appMutedForeground)
                        }
                    }
                }
                .padding(.top, AppTheme.smallPadding)
            } else if let count = summary?.holdingsCount {
                Text("\(count) holdings")
                    .font(.caption2)
                    .foregroundColor(.appMutedForeground)
                    .padding(.top, AppTheme.smallPadding)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.padding)
        .background(Color.appCard)
        .cornerRadius(AppTheme.cornerRadius)
    }
}

struct PortfolioSectionHeader: View {
    let title: String
    let totalValueRsd: String?
    let totalProfitRsd: String?
    let totalProfitPct: String?

    init<P>(title: String, group: PortfolioGroup<P>) {
        self.title = title
        self.totalValueRsd = group.totalValueRsd
        self.totalProfitRsd = group.totalProfitRsd
        self.totalProfitPct = group.totalProfitPct
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
                .foregroundColor(.appForeground)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let value = RSDFormat.money(totalValueRsd) {
                    Text(value)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appForeground)
                }
                if let profit = RSDFormat.signedMoney(totalProfitRsd) {
                    HStack(spacing: 2) {
                        Text(profit)
                        if let pct = RSDFormat.signedPercent(totalProfitPct) {
                            Text("(\(pct))")
                        }
                    }
                    .font(.caption2)
                    .foregroundColor(RSDFormat.isLoss(totalProfitRsd) ? .appDestructive : .green)
                }
            }
        }
        .padding(.top, AppTheme.smallPadding)
    }
}

struct SecurityPositionRow: View {
    let position: SecurityPosition

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallPadding) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(position.symbol)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.appForeground)
                        AssetTypeBadge(text: position.assetType.capitalized)
                    }
                    if let price = RSDFormat.money(position.currentPriceRsd) {
                        Text("\(position.quantity) × \(price)")
                            .font(.caption)
                            .foregroundColor(.appMutedForeground)
                    } else {
                        Text("Qty \(position.quantity)")
                            .font(.caption)
                            .foregroundColor(.appMutedForeground)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if let value = RSDFormat.money(position.currentValueRsd) {
                        Text(value)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.appForeground)
                    }
                    HStack(spacing: 4) {
                        if let profit = RSDFormat.signedMoney(position.profitLossRsd) {
                            Text(profit)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        if let pct = RSDFormat.signedPercent(position.profitLossPct) {
                            Text("(\(pct))")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(RSDFormat.isLoss(position.profitLossRsd) ? .appDestructive : .green)
                }

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.appMutedForeground)
                    .padding(.top, 4)
            }

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    if let avg = RSDFormat.money(position.avgCostRsd) {
                        Text("Avg cost \(avg)")
                            .font(.caption2)
                            .foregroundColor(.appMutedForeground)
                    }
                    if !RSDFormat.isZero(position.dividendsReceivedRsd),
                       let dividends = RSDFormat.money(position.dividendsReceivedRsd) {
                        Text("Dividends \(dividends)")
                            .font(.caption2)
                            .foregroundColor(.appPrimary)
                    }
                }

                Spacer()

                if let date = RSDFormat.date(position.lastUpdated) {
                    Text("Updated \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(.appMutedForeground)
                }
            }
        }
        .padding(AppTheme.padding)
        .background(Color.appCard)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.appForeground.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct FundPositionRow: View {
    let position: FundPosition

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallPadding) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(position.fundName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.appForeground)
                            .lineLimit(1)
                        if let status = position.fundStatus, !status.isEmpty {
                            AssetTypeBadge(text: status.capitalized)
                        }
                    }
                    if let invested = RSDFormat.money(position.amountInvestedRsd) {
                        Text("Invested \(invested)")
                            .font(.caption)
                            .foregroundColor(.appMutedForeground)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if let value = RSDFormat.money(position.currentValueRsd) {
                        Text(value)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.appForeground)
                    }
                    HStack(spacing: 4) {
                        if let profit = RSDFormat.signedMoney(position.profitLossRsd) {
                            Text(profit)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        if let pct = RSDFormat.signedPercent(position.profitLossPct) {
                            Text("(\(pct))")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(RSDFormat.isLoss(position.profitLossRsd) ? .appDestructive : .green)
                }
            }

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    if let share = RSDFormat.percent(position.pctOfFund) {
                        Text("Share of fund \(share)")
                            .font(.caption2)
                            .foregroundColor(.appMutedForeground)
                    }
                    if !RSDFormat.isZero(position.dividendsReceivedRsd),
                       let dividends = RSDFormat.money(position.dividendsReceivedRsd) {
                        Text("Dividends \(dividends)")
                            .font(.caption2)
                            .foregroundColor(.appPrimary)
                    }
                }

                Spacer()

                if let date = RSDFormat.date(position.lastUpdated) {
                    Text("Updated \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(.appMutedForeground)
                }
            }
        }
        .padding(AppTheme.padding)
        .background(Color.appCard)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.appForeground.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct AssetTypeBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.appPrimary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.appPrimary.opacity(0.12))
            .clipShape(Capsule())
    }
}
