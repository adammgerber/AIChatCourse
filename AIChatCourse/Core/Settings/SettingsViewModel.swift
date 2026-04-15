//
//  SettingsViewModel.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 13/04/2026.
//

import SwiftUI
import SwiftfulUtilities

@MainActor
protocol SettingsInteractor {
    var auth: UserAuthInfo? { get }
    
    func trackEvent(event: LoggableEvent)
    func deleteUserProfile()
    func deleteAccount() async throws
    func signOut() async throws
    func updateAppState(showTabBarView: Bool)
}

extension CoreInteractor: SettingsInteractor {}

@Observable
@MainActor
class SettingsViewModel {
    
    private let interactor: SettingsInteractor
    
    private(set) var isPremium: Bool = false
    private(set) var isAnonymousUser: Bool = false
    
    var showCreateAccountView: Bool = false
    var showAlert: AnyAppAlert?
    var showRatingsModal: Bool = false
    
    init(interactor: SettingsInteractor) {
        self.interactor = interactor
    }
    
    func onRatingsButtonPressed() {
        interactor.trackEvent(event: Event.ratingsPressed)
        showRatingsModal = true
    }
    
    func onEnjoyingAppYesPressed() {
        interactor.trackEvent(event: Event.ratingsYesPressed)
        showRatingsModal = false
        AppStoreRatingsHelper.requestRatingsReview()
    }
    
    func onEnjoyingAppNoPressed() {
        interactor.trackEvent(event: Event.ratingsNoPressed)
        showRatingsModal = false
    }
    
    func onContactUsPressed() {
        interactor.trackEvent(event: Event.contactUsPressed)
        let email = "hello@swiftful-thinking.com"
        let emailString = "mailto:\(email)"
        
        guard let url = URL(string: emailString), UIApplication.shared.canOpenURL(url) else {
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    func onSignOutPressed(onDismiss: @escaping () async -> Void) {
        interactor.trackEvent(event: Event.signOutStart)
        
        Task {
            do {
                try await interactor.signOut()
                interactor.trackEvent(event: Event.signOutSuccess)

                await onDismiss()
                interactor.updateAppState(showTabBarView: false)
            } catch {
                showAlert = AnyAppAlert(error: error)
                interactor.trackEvent(event: Event.signOutFail(error: error))
            }
        }
    }
    
    func onDeleteAccountPressed(onDismiss: @escaping @MainActor () async -> Void) {
        interactor.trackEvent(event: Event.deleteAccountStart)

        showAlert = AnyAppAlert(
            title: "Delete Account?",
            subtitle: "This action is permanent and cannot be undone. Your data will be deleted from our server forever.",
            buttons: {
                AnyView(
                    Button("Delete", role: .destructive, action: {
                        self.onDeleteAccountConfirmed(onDismiss: onDismiss)
                    })
                )
            }
        )
    }
    
    func onDeleteAccountConfirmed(onDismiss: @escaping () async -> Void) {
        interactor.trackEvent(event: Event.deleteAccountStartConfirm)

        Task {
            do {
                try await interactor.deleteAccount()
                interactor.trackEvent(event: Event.deleteAccountSuccess)

                await onDismiss()
                interactor.updateAppState(showTabBarView: false)
            } catch {
                showAlert = AnyAppAlert(error: error)
                interactor.trackEvent(event: Event.deleteAccountFail(error: error))
            }
        }
    }
    
    func onCreateAccountPressed() {
        showCreateAccountView = true
        interactor.trackEvent(event: Event.createAccountPressed)
    }
    
    func setAnonymousAccountStatus() {
        isAnonymousUser = interactor.auth?.isAnonymous == true
    }
    
    enum Event: LoggableEvent {
        case signOutStart
        case signOutSuccess
        case signOutFail(error: Error)
        case deleteAccountStart
        case deleteAccountStartConfirm
        case deleteAccountSuccess
        case deleteAccountFail(error: Error)
        case createAccountPressed
        case contactUsPressed
        case ratingsPressed
        case ratingsYesPressed
        case ratingsNoPressed

        var eventName: String {
            switch self {
            case .signOutStart:                 return "SettingsView_SignOut_Start"
            case .signOutSuccess:               return "SettingsView_SignOut_Success"
            case .signOutFail:                  return "SettingsView_SignOut_Fail"
            case .deleteAccountStart:           return "SettingsView_DeleteAccount_Start"
            case .deleteAccountStartConfirm:    return "SettingsView_DeleteAccount_StartConfirm"
            case .deleteAccountSuccess:         return "SettingsView_DeleteAccount_Success"
            case .deleteAccountFail:            return "SettingsView_DeleteAccount_Fail"
            case .createAccountPressed:         return "SettingsView_CreateAccount_Pressed"
            case .contactUsPressed:             return "SettingsView_ContactUs_Pressed"
            case .ratingsPressed:               return "SettingsView_Ratings_Pressed"
            case .ratingsYesPressed:            return "SettingsView_RatingsYes_Pressed"
            case .ratingsNoPressed:             return "SettingsView_RatingsNo_Pressed"
            }
        }
        
        var parameters: [String: Any]? {
            switch self {
            case .signOutFail(error: let error), .deleteAccountFail(error: let error):
                return error.eventParameters
            default:
                return nil
            }
        }
        
        var type: LogType {
            switch self {
            case .signOutFail, .deleteAccountFail:
                return .severe
            default:
                return .analytic
            }
        }
    }
}

