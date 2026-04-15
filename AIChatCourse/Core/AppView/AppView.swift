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
    @Environment(DependencyContainer.self) private var container

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
                        TabBarView()
                    },
                    onboardingView: {
                        WelcomeView(viewModel: WelcomeViewModel(interactor: CoreInteractor(container: container)))
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
    return AppView(
        viewModel: AppViewModel(interactor: CoreInteractor(container: container))
    )
    .previewEnvironment()
}
#Preview("AppView - Onboarding") {
    let container = DevPreview.shared.container
    container.register(UserManager.self, service: UserManager(services: MockUserServices(user: nil)))
    container.register(AuthManager.self, service: AuthManager(service: MockAuthService(user: nil)))
    container.register(AppState.self, service: AppState(showTabBar: true))
     
    return AppView(
        viewModel: AppViewModel(interactor: CoreInteractor(container: container))
    )
    .previewEnvironment()
}
