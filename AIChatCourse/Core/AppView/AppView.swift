//
//  AppView.swift
//  AIChatCourse
//
//  Created by Adam Gerber
//
import SwiftUI
import SwiftfulUtilities

struct AppView: View {
    @State var viewModel: AppViewModel
    @Environment(CoreBuilder.self) private var builder

    var body: some View {
        RootView(
            delegate: RootDelegate(
                onApplicationDidAppear: nil,
                onApplicationWillEnterForeground: { _ in
                    print("Entering foreground: resuming session if it was paused")
                    Task {
                        await viewModel.checkUserStatus()
                    }
                },
                onApplicationDidBecomeActive: nil,
                onApplicationWillResignActive: nil,
                onApplicationDidEnterBackground: nil,
                onApplicationWillTerminate: nil
            ),
            content: {
                AppViewBuilder(
                    showTabBar: viewModel.showTabBar,
                    tabbarView: {
                        builder.tabBarView()
                    },
                    onboardingView: {
                        builder.welcomeView()
                    }
                )
                .task {
                    await viewModel.checkUserStatus()
                }
                .task {
                    try? await Task.sleep(for: .seconds(2))
                    await viewModel.showATTPromptIfNeeded()
                }
                .onChange(of: viewModel.showTabBar) { _, showTabBar in
                    if !showTabBar {
                        Task {
                            await viewModel.checkUserStatus()
                        }
                    }
                }
            }
        )
    }
}

#Preview("AppView - Tabbar") {
    let container = DevPreview.shared.container
    container.register(AppState.self, service: AppState(showTabBar: true))
    let builder = CoreBuilder(interactor: CoreInteractor(container: container))
    return builder.appView()
        .previewEnvironment()
}

#Preview("AppView - Onboarding") {
    let container = DevPreview.shared.container
    container.register(UserManager.self, service: UserManager(services: MockUserServices(user: nil)))
    container.register(AuthManager.self, service: AuthManager(service: MockAuthService(user: nil)))
    container.register(AppState.self, service: AppState(showTabBar: true))
     
    let builder = CoreBuilder(interactor: CoreInteractor(container: container))
    return builder.appView()
        .previewEnvironment()
}
