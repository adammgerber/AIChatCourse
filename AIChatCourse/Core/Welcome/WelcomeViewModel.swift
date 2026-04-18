//
//  WelcomeViewModel.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 13/04/2026.
//

import SwiftUI

@MainActor
protocol WelcomeViewInteractor {
    func trackEvent(event: LoggableEvent)
    func updateAppState(showTabBarView: Bool)
    
}

extension CoreInteractor: WelcomeViewInteractor {}

@Observable
@MainActor
class WelcomeViewModel {
    
    private(set) var imageName: String = Constants.randomImage
    var showSignInView: Bool = false
    var path: [OnboardingPathOption] = []
    
    private let interactor: WelcomeViewInteractor
    
    init(interactor: WelcomeViewInteractor) {
        self.interactor = interactor
    }
    
    func handleDidSignIn(isNewUser: Bool) {
        interactor.trackEvent(event: Event.didSignIn(isNewUser: isNewUser))
        
        if isNewUser {
            // Do nothing, user goes through onboarding
        } else {
            // Push into tabbar view
            interactor.updateAppState(showTabBarView: true)
        }
    }
    
    func onSignInPresssed() {
        showSignInView = true
        interactor.trackEvent(event: Event.signInPressed)
    }
    
    func onGetStartedPressed() {
        path.append(.introView)
    }
    
    enum Event: LoggableEvent {
        case didSignIn(isNewUser: Bool)
        case signInPressed
        
        var eventName: String {
            switch self {
            case .didSignIn:          return "WelcomeView_DidSignIn"
            case .signInPressed:      return "WelcomeView_SignIn_Pressed"
            }
        }
        
        var parameters: [String: Any]? {
            switch self {
            case .didSignIn(isNewUser: let isNewUser):
                return [
                    "is_new_user": isNewUser
                ]
            default:
                return nil
            }
        }
        
        var type: LogType {
            switch self {
            default:
                return .analytic
            }
        }
    }
}
