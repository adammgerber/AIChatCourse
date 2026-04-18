//
//  CoreBuilder.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 15/04/2026.
//

import SwiftUI

@Observable
@MainActor
class CoreBuilder {
    let interactor: CoreInteractor
    
    init(interactor: CoreInteractor) {
        self.interactor = interactor
    }
    
    func appView() -> some View {
        AppView(
            viewModel: AppViewModel(interactor: interactor)
        )
    }
    
    func tabBarView() -> some View {
        TabBarView()
    }
    
    func welcomeView() -> some View {
        WelcomeView(
            viewModel: WelcomeViewModel(
                interactor: interactor
            )
        )
    }
    
    func onboardingColorView(delegate: OnboardingColorDelegate) -> some View {
        OnboardingColorView(viewModel: OnboardingColorViewModel(
            interactor: interactor
        ),
        delegate: delegate)
    }
    
    func onboardingCompletedView(delegate: OnboardingCompletedDelegate) -> some View {
        OnboardingCompletedView(viewModel: OnboardingCompleteViewModel(interactor: interactor),
                                delegate: delegate)
    }
    
    func onboardingIntroView(delegate: OnboardingIntroDelegate) -> some View {
        OnboardingIntroView(viewModel: OnboardingIntroViewModel(interactor: interactor),
                                delegate: delegate)
    }
    
    func createAccountView(delegate: CreateAccountDelegate = CreateAccountDelegate()) -> some View {
        CreateAccountView(
            viewModel: CreateAccountViewModel(interactor: interactor),
            delegate: delegate
        )
    }
    
    func chatsView() -> some View {
        ChatsView(
            viewModel: ChatsViewModel(
                interactor: interactor
            )
        )
    }
    
    func chatView(delegate: ChatViewDelegate = ChatViewDelegate()) -> some View {
        ChatView(
            viewModel: ChatViewModel(
                interactor: interactor
            ),
            delegate: delegate
        )
    }
    
    func categoryListView(delegate: CategoryListDelegate) -> some View {
        CategoryListView(
            viewModel: CategoryListViewModel(interactor: interactor),
            delegate: delegate
        )
    }
    
    func createAvatarView() -> some View {
        CreateAvatarView(
            viewModel: CreateAvatarViewModel(
                interactor: interactor
            )
        )
    }
    
    func exploreView() -> some View {
        ExploreView(viewModel: ExploreViewModel(interactor: interactor))
    }
    
    func settingsView() -> some View {
        SettingsView(viewModel: SettingsViewModel(interactor: interactor))
    }
    
    func profileView() -> some View {
        ProfileView(
            viewModel: ProfileViewModel(interactor: interactor)
        )
    }
    
    // MARK: CELLS
    
    func chatRowCell(delegate: ChatRowCellDelegate = ChatRowCellDelegate()) -> some View {
        ChatRowCellViewBuilder(
            viewModel: ChatRowCellViewModel(
                interactor: interactor
            ),
            delegate: delegate
        )
    }
}
