//
//  SettingsView.swift
//  AIChatCourse
//
//

import SwiftUI

struct SettingsView: View {
    
    @State var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(CoreBuilder.self) private var builder

    var body: some View {
        NavigationStack {
            List {
                accountSection
                purchaseSection
                applicationSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $viewModel.showCreateAccountView, onDismiss: {
                viewModel.setAnonymousAccountStatus()
            }, content: {
                builder.createAccountView()
                    .presentationDetents([.medium])
            })
            .onAppear {
                viewModel.setAnonymousAccountStatus()
            }
            .showCustomAlert(alert: $viewModel.showAlert)
            .screenAppearAnalytics(name: "SettingsView")
            .showModal(showModal: $viewModel.showRatingsModal) {
                ratingsModal
            }
        }
    }
    
    func dismissScreen() async {
        dismiss()
        try? await Task.sleep(for: .seconds(1))
    }
    
    private var ratingsModal: some View {
        CustomModalView(
            title: "Are you enjoying AIChat?",
            subtitle: "We'd love to hear your feedback!",
            primaryButtonTitle: "Yes",
            primaryButtonAction: {
                viewModel.onEnjoyingAppYesPressed()
            },
            secondaryButtonTitle: "No",
            secondaryButtonAction: {
                viewModel.onEnjoyingAppNoPressed()
            }
        )
    }
    
    private var accountSection: some View {
        Section {
            if viewModel.isAnonymousUser {
                Text("Save & back-up account")
                    .rowFormatting()
                    .anyButton(.highlight) {
                        viewModel.onCreateAccountPressed()
                    }
                    .removeListRowFormatting()
            } else {
                Text("Sign out")
                    .rowFormatting()
                    .anyButton(.highlight) {
                        viewModel.onSignOutPressed(onDismiss: {
                            await dismissScreen()
                        })
                    }
                    .removeListRowFormatting()
            }
            
            Text("Delete account")
                .foregroundStyle(.red)
                .rowFormatting()
                .anyButton(.highlight) {
                    viewModel.onDeleteAccountPressed(onDismiss: {
                        await dismissScreen()
                    })
                }
                .removeListRowFormatting()
        } header: {
            Text("Account")
        }
    }
    
    private var purchaseSection: some View {
        Section {
            HStack(spacing: 8) {
                Text("Account status: \(viewModel.isPremium ? "PREMIUM" : "FREE")")
                Spacer(minLength: 0)
                if viewModel.isPremium {
                    Text("MANAGE")
                        .badgeButton()
                }
            }
            .rowFormatting()
            .anyButton(.highlight) {

            }
            .disabled(!viewModel.isPremium)
            .removeListRowFormatting()
        } header: {
            Text("Purchases")
        }
    }
    
    private var applicationSection: some View {
        Section {
            Text("Rate us on the App Store!")
                .foregroundStyle(.blue)
                .rowFormatting()
                .anyButton(.highlight, action: {
                    viewModel.onRatingsButtonPressed()
                })
                .removeListRowFormatting()
            
            HStack(spacing: 8) {
                Text("Version")
                Spacer(minLength: 0)
                Text(Utilities.appVersion ?? "")
                    .foregroundStyle(.secondary)
            }
            .rowFormatting()
            .removeListRowFormatting()
            
            HStack(spacing: 8) {
                Text("Build Number")
                Spacer(minLength: 0)
                Text(Utilities.buildNumber ?? "")
                    .foregroundStyle(.secondary)
            }
            .rowFormatting()
            .removeListRowFormatting()
            
            Text("Contact us")
                .foregroundStyle(.blue)
                .rowFormatting()
                .anyButton(.highlight, action: {
                    viewModel.onContactUsPressed()
                })
                .removeListRowFormatting()
        } header: {
            Text("Application")
        } footer: {
            Text("Created by Swiftful Thinking.\nLearn more at www.swiftful-thinking.com.")
                .baselineOffset(6)
        }
    }
}

fileprivate extension View {
    func rowFormatting() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(uiColor: .systemBackground))
    }
}

#Preview("No auth") {
    
    let container = DevPreview.shared.container
    container.register(AuthManager.self, service: AuthManager(service: MockAuthService(user: nil)))
    container.register(UserManager.self, service: UserManager(services: MockUserServices(user: nil)))
    
    let builder = CoreBuilder(interactor: CoreInteractor(container: container))
    
    return builder.settingsView().previewEnvironment()
}
#Preview("Anonymous") {
    let container = DevPreview.shared.container
    container.register(AuthManager.self, service: AuthManager(service: MockAuthService(user: UserAuthInfo.mock(isAnonymous: true))))
    container.register(UserManager.self, service: UserManager(services: MockUserServices(user: .mock)))
    
    let builder = CoreBuilder(interactor: CoreInteractor(container: container))
    
    return builder.settingsView().previewEnvironment()
}
#Preview("Not anonymous") {
    let container = DevPreview.shared.container
    container.register(AuthManager.self, service: AuthManager(service: MockAuthService(user: UserAuthInfo.mock(isAnonymous: false))))
    container.register(UserManager.self, service: UserManager(services: MockUserServices(user: .mock)))
    
    let builder = CoreBuilder(interactor: CoreInteractor(container: container))
    
    return builder.settingsView().previewEnvironment()
}
