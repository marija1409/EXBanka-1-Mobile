import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: LoginViewModel

    init() {
        _viewModel = StateObject(wrappedValue: LoginViewModel(appState: AppState.shared))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo / branding
                VStack(spacing: AppTheme.smallPadding) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.appPrimary)
                    Text("Banka")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.appForeground)
                    Text("Your digital bank")
                        .font(.subheadline)
                        .foregroundColor(.appMutedForeground)
                }
                .padding(.bottom, AppTheme.largePadding * 2)

                VStack(spacing: AppTheme.padding) {
                    BankaTextField(title: "Email", text: $viewModel.email)
                    BankaSecureField(title: "Password", text: $viewModel.password)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.appDestructive)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: {
                        Task { await viewModel.login() }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .appPrimaryForeground))
                                .frame(maxWidth: .infinity, minHeight: 48)
                        } else {
                            Text("Sign In")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.appPrimaryForeground)
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                    }
                    .background(Color.appPrimary)
                    .cornerRadius(AppTheme.cornerRadius)
                    .disabled(viewModel.isLoading)
                }
                .padding(AppTheme.largePadding)
                .background(Color.appCard)
                .cornerRadius(AppTheme.cornerRadius * 1.4)
                .shadow(color: Color.appForeground.opacity(0.08), radius: 12, x: 0, y: 4)
                .padding(.horizontal, AppTheme.padding)

                Spacer()
            }
        }
    }
}

struct BankaTextField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.appMutedForeground)
            TextField("", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(Color.appMuted)
                .cornerRadius(AppTheme.cornerRadius)
                .foregroundColor(.appForeground)
        }
    }
}

struct BankaSecureField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.appMutedForeground)
            SecureField("", text: $text)
                .padding(12)
                .background(Color.appMuted)
                .cornerRadius(AppTheme.cornerRadius)
                .foregroundColor(.appForeground)
        }
    }
}
