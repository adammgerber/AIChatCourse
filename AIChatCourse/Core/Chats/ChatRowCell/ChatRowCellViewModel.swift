//
//  ChatRowCellViewModel.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 12/04/2026.
//

import SwiftUI

@MainActor
protocol ChatRowCellInteractor {
    func trackEvent(event: LoggableEvent)
    var auth: UserAuthInfo? { get }
    func getAvatar(id: String) async throws -> AvatarModel
    func getLastChatMessage(chatId: String) async throws -> ChatMessageModel?
    
}

extension CoreInteractor: ChatRowCellInteractor {}

@Observable
@MainActor
class ChatRowCellViewModel {
    
    private let interactor: ChatRowCellInteractor
    
    init(interactor: ChatRowCellInteractor) {
        self.interactor = interactor
    }
    
    var currentUserId: String? {
        interactor.auth?.uid
    }
 
    private(set) var avatar: AvatarModel?
    private(set) var lastChatMessage: ChatMessageModel?
    
    private(set) var didLoadAvatar: Bool = false
    private(set) var didLoadChatMessage: Bool = false
    
    var isLoading: Bool {
        if didLoadAvatar && didLoadChatMessage {
            return false
        }
        
        return true
    }
    
    var hasNewChat: Bool {
        guard let lastChatMessage, let currentUserId else { return false }
        return !lastChatMessage.hasBeenSeenBy(userId: currentUserId)
    }
    
    var subheadline: String? {
        if isLoading {
            return "xxxx xxxx xxxx xxxx"
        }
        
        if avatar == nil && lastChatMessage == nil {
            return "Error"
        }
        
        return lastChatMessage?.content?.message
    }
    
    func loadAvatar(chat: ChatModel) async {
        avatar = try? await interactor.getAvatar(id: chat.avatarId)
        didLoadAvatar = true
    }
    
    func loadLastChatMessage(chat: ChatModel) async {
        lastChatMessage = try? await interactor.getLastChatMessage(chatId: chat.id)
        didLoadChatMessage = true
    }
}
