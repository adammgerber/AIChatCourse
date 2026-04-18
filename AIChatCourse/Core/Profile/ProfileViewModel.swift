//
//  ProfileViewModel.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 28/01/2026.
//

import SwiftUI

@MainActor
protocol ProfileInteractor {
    var currentUser: UserModel? { get }
    func getAuthId() throws -> String
    func getAvatarsForAuthor(userId: String) async throws -> [AvatarModel]
    func trackEvent(event: LoggableEvent)
    func removeAuthorIdFromAvatar(avatarId: String) async throws
}

@MainActor
struct ProdProfileInteractor: ProfileInteractor {
    
    let authManager: AuthManager
    let userManager: UserManager
    let avatarManager: AvatarManager
    let logManager: LogManager
    
    init(container: DependencyContainer) {
        self.authManager = container.resolve(AuthManager.self)!
        self.userManager = container.resolve(UserManager.self)!
        self.avatarManager = container.resolve(AvatarManager.self)!
        self.logManager = container.resolve(LogManager.self)!
    }
    
    var currentUser: UserModel? {
        userManager.currentUser
    }
    
    func getAuthId() throws -> String {
        try authManager.getAuthId()
    }
    
    func getAvatarsForAuthor(userId: String) async throws -> [AvatarModel] {
        try await avatarManager.getAvatarsForAuthor(userId: userId)
    }
    
    func trackEvent(event: any LoggableEvent) {
        logManager.trackEvent(event: event)
    }
    
    func removeAuthorIdFromAvatar(avatarId: String) async throws {
        try await avatarManager.removeAuthorIdFromAvatar(avatarId: avatarId)
    }
    
}

extension CoreInteractor: ProfileInteractor {}

@Observable
@MainActor
class ProfileViewModel {
    
    private let interactor: ProfileInteractor
    
    private(set) var currentUser: UserModel?
    private(set) var myAvatars: [AvatarModel] = []
    private(set) var isLoading: Bool = true
    
    var showSettingsView: Bool = false
    var showCreateAvatarView: Bool = false
    var showAlert: AnyAppAlert?
    var path: [TabbarPathOption] = []
    
    init(interactor: ProfileInteractor) {
        self.interactor = interactor
    }

    func loadData() async {
        self.currentUser = interactor.currentUser
        interactor.trackEvent(event: Event.loadAvatarsStart)
        
        do {
            let uid = try interactor.getAuthId()
            myAvatars = try await interactor.getAvatarsForAuthor(userId: uid)
            interactor.trackEvent(event: Event.loadAvatarsSuccess(count: myAvatars.count))
        } catch {
            interactor.trackEvent(event: Event.loadAvatarsFail(error: error))
        }
        
        isLoading = false
    }
    
    func onSettingsButtonPressed() {
        showSettingsView = true
        interactor.trackEvent(event: Event.settingsPressed)
    }
    
    func onNewAvatarButtonPressed() {
        showCreateAvatarView = true
        interactor.trackEvent(event: Event.newAvatarPressed)
    }
    
    func onAvatarPressed(avatar: AvatarModel) {
        path.append(.chat(avatarId: avatar.avatarId, chat: nil))
        interactor.trackEvent(event: Event.avatarPressed(avatar: avatar))
    }
    
    func onDeleteAvatar(indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        let avatar = myAvatars[index]
        interactor.trackEvent(event: Event.deleteAvatarStart(avatar: avatar))

        Task {
            do {
                try await interactor.removeAuthorIdFromAvatar(avatarId: avatar.id)
                myAvatars.remove(at: index)
                interactor.trackEvent(event: Event.deleteAvatarSuccess(avatar: avatar))
            } catch {
                showAlert = AnyAppAlert(title: "Unable to delete avatar.", subtitle: "Please try again.")
                interactor.trackEvent(event: Event.deleteAvatarFail(error: error))
            }
        }
    }

    enum Event: LoggableEvent {
        case loadAvatarsStart
        case loadAvatarsSuccess(count: Int)
        case loadAvatarsFail(error: Error)
        case settingsPressed
        case newAvatarPressed
        case avatarPressed(avatar: AvatarModel)
        case deleteAvatarStart(avatar: AvatarModel)
        case deleteAvatarSuccess(avatar: AvatarModel)
        case deleteAvatarFail(error: Error)

        var eventName: String {
            switch self {
            case .loadAvatarsStart:         return "ProfileView_LoadAvatars_Start"
            case .loadAvatarsSuccess:       return "ProfileView_LoadAvatars_Success"
            case .loadAvatarsFail:          return "ProfileView_LoadAvatars_Fail"
            case .settingsPressed:          return "ProfileView_Settings_Pressed"
            case .newAvatarPressed:         return "ProfileView_NewAvatar_Pressed"
            case .avatarPressed:            return "ProfileView_Avatar_Pressed"
            case .deleteAvatarStart:        return "ProfileView_DeleteAvatar_Start"
            case .deleteAvatarSuccess:      return "ProfileView_DeleteAvatar_Success"
            case .deleteAvatarFail:         return "ProfileView_DeleteAvatar_Fail"
            }
        }
        
        var parameters: [String: Any]? {
            switch self {
            case .loadAvatarsSuccess(count: let count):
                return [
                    "avatars_count": count
                ]
            case .loadAvatarsFail(error: let error), .deleteAvatarFail(error: let error):
                return error.eventParameters
            case .avatarPressed(avatar: let avatar), .deleteAvatarStart(avatar: let avatar), .deleteAvatarSuccess(avatar: let avatar):
                return avatar.eventParameters
            default:
                return nil
            }
        }
        
        var type: LogType {
            switch self {
            case .loadAvatarsFail, .deleteAvatarFail:
                return .severe
            default:
                return .analytic
            }
        }
    }
}
