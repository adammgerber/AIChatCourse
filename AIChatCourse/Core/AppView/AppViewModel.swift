//
//  AppViewModel.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 28/01/2026.
//

import SwiftUI
import SwiftfulUtilities

@MainActor
protocol AppViewInteractor {
    func trackEvent(event: LoggableEvent)
    var auth: UserAuthInfo? { get }
    var showTabBar: Bool { get }
    func logIn(auth: UserAuthInfo, isNewUser: Bool) async throws
    func signInAnonymously() async throws -> (user: UserAuthInfo, isNewUser: Bool)
}

extension CoreInteractor: AppViewInteractor {}

@Observable
@MainActor
class AppViewModel {
    
    private let interactor: AppViewInteractor
    var showTabBar: Bool {
        interactor.showTabBar
    }
    
    init(interactor: AppViewInteractor) {
        self.interactor = interactor
    }
    
    func showATTPromptIfNeeded() async {
        #if !DEBUG
        let status = await AppTrackingTransparencyHelper.requestTrackingAuthorization()
        interactor.trackEvent(event: Event.attStatus(dict: status.eventParameters))
        #endif
    }
    
    func checkUserStatus() async {
        if let user = interactor.auth {
            // User is authenticated
            interactor.trackEvent(event: Event.existingAuthStart)
            
            do {
                try await interactor.logIn(auth: user, isNewUser: false)
            } catch {
                interactor.trackEvent(event: Event.existingAuthFail(error: error))
                try? await Task.sleep(for: .seconds(5))
                await checkUserStatus()
            }
        } else {
            // User is not authenticated
            interactor.trackEvent(event: Event.anonAuthStart)

            do {
                let result = try await interactor.signInAnonymously()
                
                // log in to app
                interactor.trackEvent(event: Event.anonAuthSuccess)
                
                // Log in
                try await interactor.logIn(auth: result.user, isNewUser: result.isNewUser)
            } catch {
                interactor.trackEvent(event: Event.anonAuthFail(error: error))
                try? await Task.sleep(for: .seconds(5))
                await checkUserStatus()
            }
        }
    }
    
    enum Event: LoggableEvent {
        case existingAuthStart
        case existingAuthFail(error: Error)
        case anonAuthStart
        case anonAuthSuccess
        case anonAuthFail(error: Error)
        case attStatus(dict: [String: Any])
        case enteredBackground

        var eventName: String {
            switch self {
            case .existingAuthStart:    return "AppView_ExistingAuth_Start"
            case .existingAuthFail:     return "AppView_ExistingAuth_Fail"
            case .anonAuthStart:        return "AppView_AnonAuth_Start"
            case .anonAuthSuccess:      return "AppView_AnonAuth_Success"
            case .anonAuthFail:         return "AppView_AnonAuth_Fail"
            case .attStatus:            return "AppView_ATTStatus"
            case .enteredBackground:    return "AppView_EnteredBackground"
            }
        }
        
        var parameters: [String: Any]? {
            switch self {
            case .existingAuthFail(error: let error), .anonAuthFail(error: let error):
                return error.eventParameters
            case .attStatus(dict: let dict):
                return dict
            default:
                return nil
            }
        }
        
        var type: LogType {
            switch self {
            case .existingAuthFail, .anonAuthFail:
                return .severe
            default:
                return .analytic
            }
        }
    }
}
