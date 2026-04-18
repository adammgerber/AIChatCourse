//
//  OnboardingIntroViewModel.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 18/04/2026.
//

import SwiftUI

@MainActor
protocol OnboardingIntroInteractor {
    func trackEvent(event: LoggableEvent)
}

extension CoreInteractor: OnboardingIntroInteractor { }

@Observable
@MainActor
class OnboardingIntroViewModel {
    
    private let interactor: OnboardingIntroInteractor
    
    init(interactor: OnboardingIntroInteractor) {
        self.interactor = interactor
    }
    
    func onContinueButtonPressed(path: Binding<[OnboardingPathOption]>) {
        path.wrappedValue.append(.colorView)
    }
}
