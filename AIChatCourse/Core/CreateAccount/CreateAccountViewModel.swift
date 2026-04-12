//
//  CreateAccountViewModel.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 12/04/2026.
//

import SwiftUI

@MainActor
protocol CreateAccountInteractor {
    func trackEvent(event: LoggableEvent)
    func signInApple() async throws -> (user: UserAuthInfo, isNewUser: Bool)
    func logIn(auth: UserAuthInfo, isNewUser: Bool) async throws
}

extension CoreInteractor: CreateAccountInteractor {}

@Observable
@MainActor
class CreateAccountViewModel {
    
    private let interactor: CreateAccountInteractor
    
    init(interactor: CreateAccountInteractor) {
        self.interactor = interactor
    }
    
    func onSignInApplePressed(onDidSignInSuccessfully: @escaping (_ isNewUser: Bool) -> Void) {
        interactor.trackEvent(event: Event.appleAuthStart)
        
        Task {
            do {
                let result = try await interactor.signInApple()
                interactor.trackEvent(event: Event.appleAuthSuccess(user: result.user, isNewUser: result.isNewUser))
                
                try await interactor.logIn(auth: result.user, isNewUser: result.isNewUser)
                interactor.trackEvent(event: Event.appleAuthLoginSuccess(user: result.user, isNewUser: result.isNewUser))
                
                onDidSignInSuccessfully(result.isNewUser)
            } catch {
                interactor.trackEvent(event: Event.appleAuthFail(error: error))
            }
        }
    }
    
    enum Event: LoggableEvent {
        
        case appleAuthStart
        case appleAuthSuccess(user: UserAuthInfo, isNewUser: Bool)
        case appleAuthLoginSuccess(user: UserAuthInfo, isNewUser: Bool)
        case appleAuthFail(error: Error)
        
        var eventName: String {
            switch self {
            case .appleAuthStart:           return "CreateAccountView_AppleAuth_Start"
            case .appleAuthSuccess:         return "CreateAccountView_AppleAuth_Success"
            case .appleAuthLoginSuccess:    return "CreateAccountView_AppleAuth_LoginSuccess"
            case .appleAuthFail:            return "CreateAccountView_AppleAuth_Fail"
            }
        }
        
        var parameters: [String: Any]? {
            switch self {
            case .appleAuthSuccess(user: let user, isNewUser: let isNewUser),
                    .appleAuthLoginSuccess(user: let user, isNewUser: let isNewUser):
                var dict = user.eventParameters
                dict["is_new_user"] = isNewUser
                return dict
            case .appleAuthFail(error: let error):
                return error.eventParameters
            default:
                return nil
            }
        }
        
        var type: LogType {
            switch self {
            case .appleAuthFail:
                return .severe
            default:
                return .analytic
            }
        }
    }
}
