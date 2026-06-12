import SwiftUI

struct HoldingDetailView: View {
    let position: SecurityPosition
    @StateObject private var viewModel: HoldingDetailViewModel

    init(position: SecurityPosition) {
        self.position = position
        _viewModel = StateObject(wrappedValue: HoldingDetailViewModel(holdingId: position.holdingId))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.padding) {
                    positionCard
                    tradesCard
                }
                .padding(AppTheme.padding)
            }
            .refreshable { await viewModel.load() }
        }
        .navigationTitle(position.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onChange(of: viewModel.directionFilter) { _, _ in
            Task { await viewModel.load() }
        }
    }

    private var positionCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallPadding) {
            HStack(spacing: 6) {
                Text(position.symbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.appForeground)
                AssetTypeBadge(text: position.assetType.capitalized)
                Spacer()
                Text("Holding #\(position.holdingId)")
                    .font(.caption2)
                    .foregroundColor(.appMutedForeground)
            }

            LabeledRow(label: "Quantity", value: "\(position.quantity)")
            if let avg = RSDFormat.money(position.avgCostRsd) {
                LabeledRow(label: "Average Cost", value: avg)
            }
            if let price = RSDFormat.money(position.currentPriceRsd) {
                LabeledRow(label: "Current Price", value: price)
            }
            if let value = RSDFormat.money(position.currentValueRsd) {
                LabeledRow(label: "Current Value", value: value)
            }

            if let profit = RSDFormat.signedMoney(position.profitLossRsd) {
                HStack {
                    Text("Profit / Loss")
                        .font(.caption)
                        .foregroundColor(.appMutedForeground)
                    Spacer()
                    HStack(spacing: 4) {
                        Text(profit)
                        if let pct = RSDFormat.signedPercent(position.profitLossPct) {
                            Text("(\(pct))")
                        }
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(RSDFormat.isLoss(position.profitLossRsd) ? .appDestructive : .green)
                }
            }

            if let dividends = RSDFormat.money(position.dividendsReceivedRsd) {
                LabeledRow(label: "Dividends Received", value: dividends)
            }
            if let date = RSDFormat.date(position.lastUpdated) {
                LabeledRow(label: "Last Updated", value: date.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .padding(AppTheme.padding)
        .background(Color.appCard)
        .cornerRadius(AppTheme.cornerRadius)
    }

    private var tradesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallPadding) {
            Text("Trades")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.appForeground)

            Picker("Direction", selection: $viewModel.directionFilter) {
                ForEach(TradeDirectionFilter.allCases) { filter in
                    Text(filter.label).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, AppTheme.smallPadding)

            if viewModel.isLoading && viewModel.transactions.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding()
            } else if let error = viewModel.errorMessage, viewModel.transactions.isEmpty {
                VStack(spacing: AppTheme.smallPadding) {
                    Text(error).font(.caption).foregroundColor(.appDestructive)
                    Button("Retry") { Task { await viewModel.load() } }
                        .font(.caption)
                        .foregroundColor(.appPrimary)
                }
                .frame(maxWidth: .infinity)
            } else if viewModel.transactions.isEmpty {
                Text("No trades for this holding.")
                    .font(.subheadline)
                    .foregroundColor(.appMutedForeground)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                if let error = viewModel.errorMessage {
                    Text(error).font(.caption).foregroundColor(.appDestructive)
                }

                ForEach(viewModel.transactions) { transaction in
                    TransactionTradeRow(transaction: transaction)
                    if transaction.id != viewModel.transactions.last?.id {
                        Divider()
                    }
                }

                if viewModel.hasMore {
                    Button(action: { Task { await viewModel.loadMore() } }) {
                        if viewModel.isLoadingMore {
                            ProgressView().frame(maxWidth: .infinity, minHeight: 32)
                        } else {
                            Text("Load More")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.appPrimary)
                                .frame(maxWidth: .infinity, minHeight: 32)
                        }
                    }
                    .disabled(viewModel.isLoadingMore)
                }

                Text("Showing \(viewModel.transactions.count) of \(viewModel.totalCount)")
                    .font(.caption2)
                    .foregroundColor(.appMutedForeground)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(AppTheme.padding)
        .background(Color.appCard)
        .cornerRadius(AppTheme.cornerRadius)
    }
}

struct TransactionTradeRow: View {
    let transaction: HoldingTransaction

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                HStack(spacing: 6) {
                    Text(transaction.direction.uppercased())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(transaction.isBuy ? .green : .appDestructive)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((transaction.isBuy ? Color.green : Color.appDestructive).opacity(0.12))
                        .cornerRadius(4)

                    if let unitPrice = amount(transaction.pricePerUnit, transaction.nativeCurrency) {
                        Text("\(transaction.quantity) × \(unitPrice)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.appForeground)
                    } else {
                        Text("Qty \(transaction.quantity)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.appForeground)
                    }
                }

                Spacer()

                if let converted = amount(transaction.convertedAmount, transaction.accountCurrency) {
                    Text(converted)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.appForeground)
                }
            }

            HStack {
                if let native = amount(transaction.nativeAmount, transaction.nativeCurrency) {
                    Text(native)
                        .font(.caption2)
                        .foregroundColor(.appMutedForeground)
                }
                if let fx = RSDFormat.amount(transaction.fxRate) {
                    Text("· FX \(fx)")
                        .font(.caption2)
                        .foregroundColor(.appMutedForeground)
                }
                if let fee = amount(transaction.commission, transaction.accountCurrency) {
                    Text("· Fee \(fee)")
                        .font(.caption2)
                        .foregroundColor(.appMutedForeground)
                }

                Spacer()

                if let date = RSDFormat.date(transaction.executedAt) {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.appMutedForeground)
                }
            }

            HStack(spacing: 4) {
                if let orderId = transaction.orderId {
                    Text("Order #\(orderId)")
                }
                if let accountId = transaction.accountId {
                    Text("· Account #\(accountId)")
                }
            }
            .font(.caption2)
            .foregroundColor(.appMutedForeground)
        }
        .padding(.vertical, 4)
    }

    private func amount(_ raw: String?, _ currency: String?) -> String? {
        guard let formatted = RSDFormat.amount(raw) else { return nil }
        guard let currency, !currency.isEmpty else { return formatted }
        return "\(formatted) \(currency)"
    }
}
