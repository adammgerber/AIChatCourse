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
    
    func createAccountView(delegate: CreateAccountDelegate = CreateAccountDelegate()) -> some View {
        CreateAccountView(
            viewModel: CreateAccountViewModel(interactor: interactor),
            delegate: delegate
        )
    }
    
    func exploreView() -> some View {
        ExploreView(viewModel: ExploreViewModel(interactor: interactor))
    }
}
