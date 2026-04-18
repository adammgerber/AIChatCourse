//
//  OnboardingCompletedViewModel.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 18/04/2026.
//

import SwiftUI

@MainActor
protocol OnboardingCompleteInteractor {
    func trackEvent(event: LoggableEvent)
    func markOnboardingCompleteForCurrentUser(profileColorHex: String) async throws
    
}

extension CoreInteractor: OnboardingCompleteInteractor {}

@Observable
@MainActor
class OnboardingCompleteViewModel {
    
    private let interactor: OnboardingCompleteInteractor
    
    init(interactor: OnboardingCompleteInteractor) {
        self.interactor = interactor
    }
    
    private(set) var isCompletingProfileSetup: Bool = false
   
    var showAlert: AnyAppAlert?
    
    func onFinishButtonPressed(selectedColor: Color, onShowTabBarView: @escaping () -> Void) {
        isCompletingProfileSetup = true
        interactor.trackEvent(event: Event.finishStart)
        
        Task {
            do {
                let hex = selectedColor.asHex()
                try await interactor.markOnboardingCompleteForCurrentUser(profileColorHex: hex)
                interactor.trackEvent(event: Event.finishSuccess(hex: hex))

                // dismiss screen
                isCompletingProfileSetup = false
                onShowTabBarView()
            } catch {
                showAlert = AnyAppAlert(error: error)
                interactor.trackEvent(event: Event.finishFail(error: error))
            }
        }
    }
    
    enum Event: LoggableEvent {
        case finishStart
        case finishSuccess(hex: String)
        case finishFail(error: Error)

        var eventName: String {
            switch self {
            case .finishStart:         return "OnboardingCompletedView_Finish_Start"
            case .finishSuccess:       return "OnboardingCompletedView_Finish_Success"
            case .finishFail:          return "OnboardingCompletedView_Finish_Fail"
            }
        }
        
        var parameters: [String: Any]? {
            switch self {
            case .finishSuccess(hex: let hex):
                return [
                    "profile_color_hex": hex
                ]
            case .finishFail(error: let error):
                return error.eventParameters
            default:
                return nil
            }
        }
        
        var type: LogType {
            switch self {
            case .finishFail:
                return .severe
            default:
                return .analytic
            }
        }
    }
}
