//
//  OnboardingColorInteractor.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 28/01/2026.
//
import SwiftUI

@MainActor
protocol OnboardingColorInteractor {
    func trackEvent(event: LoggableEvent)
    
}

extension CoreInteractor: OnboardingColorInteractor {}

@Observable
@MainActor
class OnboardingColorViewModel {
    
    private let interactor: OnboardingColorInteractor
    
    init(interactor: OnboardingColorInteractor) {
        self.interactor = interactor
    }
    
    private(set) var selectedColor: Color?
    let profileColors: [Color] = [.red, .green, .orange, .blue, .mint, .purple, .cyan, .teal, .indigo]
    
    func onColorPressed(color: Color) {
        selectedColor = color
    }
    
    func onContinuePressed(path: Binding<[OnboardingPathOption]>) {
        guard let selectedColor else { return }
        path.wrappedValue.append(.completedView(selectedColor: selectedColor))
    }
    
}
