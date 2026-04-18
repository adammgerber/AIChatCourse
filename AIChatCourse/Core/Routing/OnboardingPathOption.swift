//
//  OnboardingPathOption.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 18/04/2026.
//

import SwiftUI
import Foundation

enum OnboardingPathOption: Hashable {
    case colorView
//    case communityView
    case introView
    case completedView(selectedColor: Color)
}

struct NavDestForOnboardingModuleViewModifier: ViewModifier {
    
    @Environment(CoreBuilder.self) private var builder
    let path: Binding<[OnboardingPathOption]>
    
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: OnboardingPathOption.self) { newValue in
                switch newValue {
                case .colorView:
                    builder.onboardingColorView(delegate: OnboardingColorDelegate(path: path))
                case .introView:
                    builder.onboardingIntroView(delegate: OnboardingIntroDelegate(path: path))
                case .completedView(selectedColor: let selectedColor):
                    builder.onboardingCompletedView(delegate: OnboardingCompletedDelegate(selectedColor: selectedColor))
                }
            }
    }
}

extension View {
    
    func navigationDestinationForOnboardingModule(path: Binding<[OnboardingPathOption]>) -> some View {
        modifier(NavDestForOnboardingModuleViewModifier(path: path))
    }
}

