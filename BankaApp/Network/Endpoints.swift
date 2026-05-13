import Foundation

enum Endpoint {
    static var baseURL: String { ServerEnvironment.current.baseURL }

    // Existing
    case login
    case logout
    case me
    case myAccounts
    case paymentsForAccount(accountId: Int)

    // Mobile Auth
    case mobileRequestActivation
    case mobileActivate
    case mobileRefresh

    // Mobile Device
    case mobileDevice
    case mobileDeviceDeactivate
    case mobileDeviceTransfer

    // Verification
    case pendingVerifications
    case submitVerification(challengeId: Int)
    case ackVerification(id: Int)
    case biometricVerification(challengeId: Int)
    case qrVerify(challengeId: Int)

    // Biometric Settings
    case setBiometrics
    case getBiometrics

    // Notifications
    case notifications
    case notificationUnreadCount
    case markNotificationRead(id: Int)
    case markAllNotificationsRead

    // Client read-only views
    case myAccountDetail(id: Int)
    case myCards
    case myCardDetail(id: Int)
    case myPayments
    case myPaymentDetail(id: Int)
    case myTransfers
    case myTransferDetail(id: Int)
    case myLoans
    case myLoanDetail(id: Int)
    case myLoanInstallments(loanId: Int)
    case myPortfolio
    case myPortfolioSummary
    case myOrders
    case myOrderDetail(id: Int)
    case exchangeRates

    var urlString: String {
        let base = Endpoint.baseURL
        switch self {
        case .login:                          return "\(base)/auth/login"
        case .logout:                         return "\(base)/auth/logout"
        case .me:                             return "\(base)/me"
        case .myAccounts:                     return "\(base)/me/accounts"
        case .paymentsForAccount(let id):     return "\(base)/accounts/\(id)/payments"
        case .mobileRequestActivation:        return "\(base)/mobile/auth/request-activation"
        case .mobileActivate:                 return "\(base)/mobile/auth/activate"
        case .mobileRefresh:                  return "\(base)/mobile/auth/refresh"
        case .mobileDevice:                   return "\(base)/mobile/device"
        case .mobileDeviceDeactivate:         return "\(base)/mobile/device/deactivate"
        case .mobileDeviceTransfer:           return "\(base)/mobile/device/transfer"
        case .pendingVerifications:           return "\(base)/mobile/verifications/pending"
        case .submitVerification(let id):     return "\(base)/mobile/verifications/\(id)/submit"
        case .ackVerification(let id):        return "\(base)/mobile/verifications/\(id)/ack"
        case .biometricVerification(let id):  return "\(base)/mobile/verifications/\(id)/biometric"
        case .qrVerify(let id):               return "\(base)/verify/\(id)"
        case .setBiometrics, .getBiometrics:  return "\(base)/mobile/device/biometrics"
        case .notifications:                  return "\(base)/me/notifications"
        case .notificationUnreadCount:        return "\(base)/me/notifications/unread-count"
        case .markNotificationRead(let id):   return "\(base)/me/notifications/\(id)/read"
        case .markAllNotificationsRead:       return "\(base)/me/notifications/read-all"
        case .myAccountDetail(let id):        return "\(base)/me/accounts/\(id)"
        case .myCards:                        return "\(base)/me/cards"
        case .myCardDetail(let id):           return "\(base)/me/cards/\(id)"
        case .myPayments:                     return "\(base)/me/payments"
        case .myPaymentDetail(let id):        return "\(base)/me/payments/\(id)"
        case .myTransfers:                    return "\(base)/me/transfers"
        case .myTransferDetail(let id):       return "\(base)/me/transfers/\(id)"
        case .myLoans:                        return "\(base)/me/loans"
        case .myLoanDetail(let id):           return "\(base)/me/loans/\(id)"
        case .myLoanInstallments(let id):     return "\(base)/me/loans/\(id)/installments"
        case .myPortfolio:                    return "\(base)/me/portfolio"
        case .myPortfolioSummary:             return "\(base)/me/portfolio/summary"
        case .myOrders:                       return "\(base)/me/orders"
        case .myOrderDetail(let id):          return "\(base)/me/orders/\(id)"
        case .exchangeRates:                  return "\(base)/exchange/rates"
        }
    }

    var path: String {
        URL(string: urlString)?.path ?? ""
    }

    var method: String {
        switch self {
        case .login, .logout,
             .mobileRequestActivation, .mobileActivate, .mobileRefresh,
             .mobileDeviceDeactivate, .mobileDeviceTransfer,
             .submitVerification, .ackVerification, .biometricVerification, .qrVerify,
             .setBiometrics,
             .markNotificationRead, .markAllNotificationsRead:
            return "POST"
        default:
            return "GET"
        }
    }
}
