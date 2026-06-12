import SwiftUI

struct BackendSelectorView: View {
    @ObservedObject private var config = BackendConfig.shared
    @Environment(\.dismiss) private var dismiss
    @State private var customURL: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.padding) {
                        VStack(spacing: 0) {
                            ForEach(BackendConfig.presets) { preset in
                                Button(action: {
                                    config.select(preset.url)
                                    dismiss()
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(preset.name)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.appForeground)
                                            Text(preset.url)
                                                .font(.caption)
                                                .foregroundColor(.appMutedForeground)
                                        }
                                        Spacer()
                                        if config.baseURL == preset.url {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.appPrimary)
                                        }
                                    }
                                    .padding(AppTheme.padding)
                                }
                                if preset != BackendConfig.presets.last {
                                    Divider().padding(.leading, AppTheme.padding)
                                }
                            }
                        }
                        .background(Color.appCard)
                        .cornerRadius(AppTheme.cornerRadius)

                        VStack(spacing: AppTheme.padding) {
                            BankaTextField(title: "Custom URL", text: $customURL)
                                .keyboardType(.URL)

                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.appDestructive)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Button(action: applyCustomURL) {
                                Text("Use Custom URL")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.appPrimaryForeground)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                            }
                            .background(Color.appPrimary)
                            .cornerRadius(AppTheme.cornerRadius)
                        }
                        .padding(AppTheme.padding)
                        .background(Color.appCard)
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                    .padding(AppTheme.padding)
                }
            }
            .navigationTitle("Backend Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                customURL = config.baseURL
            }
        }
    }

    private func applyCustomURL() {
        if config.select(customURL) {
            errorMessage = nil
            dismiss()
        } else {
            errorMessage = "Enter a valid http(s) URL, e.g. https://project-exbanka.bytenity.com/instance1"
        }
    }
}
