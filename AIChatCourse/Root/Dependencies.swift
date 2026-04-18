//
//  Dependencies.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 13/04/2026.
//
import SwiftUI

@MainActor
struct Dependencies {
    let container: DependencyContainer
    let authManager: AuthManager
    let userManager: UserManager
    let aiManager: AIManager
    let avatarManager: AvatarManager
    let chatManager: ChatManager
    let logManager: LogManager
    let pushManager: PushManager
    let appState: AppState
    
    init(config: BuildConfiguration) {
        
        switch config {
        case .mock(isSignedIn: let isSignedIn):
            logManager = LogManager(services: [
                ConsoleService(printParameters: false)
            ])
            authManager = AuthManager(service: MockAuthService(user: isSignedIn ? .mock() : nil), logManager: logManager)
            userManager = UserManager(services: MockUserServices(user: isSignedIn ? .mock : nil), logManager: logManager)
            aiManager = AIManager(service: MockAIService())
            avatarManager = AvatarManager(service: MockAvatarService(), local: MockLocalAvatarPersistence())
            chatManager = ChatManager(service: MockChatService())
            appState = AppState(showTabBar: isSignedIn)
            
        case .dev:
            logManager = LogManager(services: [
                ConsoleService(),
                FirebaseAnalyticsService(),
                MixpanelService(token: Keys.mixpanelToken),
                FirebaseCrashlyticsService()
            ])
            authManager = AuthManager(service: FirebaseAuthService(), logManager: logManager)
            userManager = UserManager(services: ProductionUserServices(), logManager: logManager)
            aiManager = AIManager(service: OpenAIService())
            avatarManager = AvatarManager(service: FirebaseAvatarService(), local: SwiftDataLocalAvatarPersistence())
            chatManager = ChatManager(service: FirebaseChatService())
            appState = AppState()
        case .prod:
            logManager = LogManager(services: [
               FirebaseAnalyticsService(),
               MixpanelService(token: Keys.mixpanelToken),
               FirebaseCrashlyticsService()
            ])
            authManager = AuthManager(service: FirebaseAuthService(), logManager: logManager)
            userManager = UserManager(services: ProductionUserServices(), logManager: logManager)
            aiManager = AIManager(service: OpenAIService())
            avatarManager = AvatarManager(service: FirebaseAvatarService(), local: SwiftDataLocalAvatarPersistence())
            chatManager = ChatManager(service: FirebaseChatService())
            appState = AppState()
        }
        pushManager = PushManager(logManager: logManager)
        
        let container = DependencyContainer()
        container.register(AuthManager.self, service: authManager)
        container.register(UserManager.self, service: userManager)
        container.register(AIManager.self, service: aiManager)
        container.register(AvatarManager.self, service: avatarManager)
        container.register(ChatManager.self, service: chatManager)
        container.register(LogManager.self, service: logManager)
        container.register(PushManager.self, service: pushManager)
        container.register(AppState.self, service: appState)
        self.container = container
    }
}

extension View {
    func previewEnvironment(isSignedIn: Bool = true) -> some View {
        self
            .environment(LogManager(services: []))
            .environment(CoreBuilder(interactor: CoreInteractor(container: DevPreview.shared.container)))
    }
}

@MainActor
class DevPreview {
    static let shared = DevPreview()
    
    var container: DependencyContainer {
        let container = DependencyContainer()
        container.register(AuthManager.self, service: authManager)
        container.register(UserManager.self, service: userManager)
        container.register(AIManager.self, service: aiManager)
        container.register(AvatarManager.self, service: avatarManager)
        container.register(ChatManager.self, service: chatManager)
        container.register(LogManager.self, service: logManager)
        container.register(PushManager.self, service: pushManager)
        container.register(AppState.self, service: appState)
        return container
    }
    
    let authManager: AuthManager
    let userManager: UserManager
    let aiManager: AIManager
    let avatarManager: AvatarManager
    let chatManager: ChatManager
    let logManager: LogManager
    let pushManager: PushManager
    let appState: AppState
    
    init(isSignedIn: Bool = true) {
        self.authManager = AuthManager(service: MockAuthService(user: isSignedIn ? .mock() : nil))
        self.userManager = UserManager(services: MockUserServices(user: isSignedIn ? .mock : nil))
        self.aiManager = AIManager(service: MockAIService())
        self.avatarManager = AvatarManager(service: MockAvatarService(), local: MockLocalAvatarPersistence())
        self.chatManager = ChatManager(service: FirebaseChatService())
        self.logManager = LogManager(services: [])
        self.pushManager = PushManager()
        self.appState = AppState()
    }
}
