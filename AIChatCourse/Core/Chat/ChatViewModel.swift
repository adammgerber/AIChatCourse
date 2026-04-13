//
//  ChatViewModel.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 13/04/2026.
//

import SwiftUI

@MainActor
protocol ChatInteractor {
    var currentUser: UserModel? { get }
    var auth: UserAuthInfo? { get }
//    var isPremium: Bool { get }
    
    func trackEvent(event: LoggableEvent)
    func getAuthId() throws -> String
    func getAvatar(id: String) async throws -> AvatarModel
    func addRecentAvatar(avatar: AvatarModel) throws
    func getRecentAvatars() throws -> [AvatarModel]
    
    func createNewChat(chat: ChatModel) async throws
    func reportChat(chatId: String, userId: String) async throws
    func addChatMessages(chatId: String, message: ChatMessageModel) async throws
    func deleteChat(chatId: String) async throws
    func streamChatMessages(chatId: String) -> AsyncThrowingStream<[ChatMessageModel], Error>
    func getChat(userId: String, avatarId: String) async throws -> ChatModel?
    func markChatMessageAsSeen(chatId: String, messageId: String, userId: String) async throws
   
    func generateText(chats: [AIChatModel]) async throws -> AIChatModel
}

extension CoreInteractor: ChatInteractor {}

@Observable
@MainActor
class ChatViewModel {
    
    private let interactor: ChatInteractor
    
    init(interactor: ChatInteractor) {
        self.interactor = interactor
    }
    
    private(set) var chatMessages: [ChatMessageModel] = []
    private(set) var avatar: AvatarModel?
    private(set) var currentUser: UserModel? = .mock
    private(set) var isGeneratingResponse: Bool = false
    private(set) var chat: ChatModel?
    
    var showAlert: AnyAppAlert?
    var showChatSettings: AnyAppAlert?
    var showProfileModal: Bool = false
    var textFieldText: String = ""
    var scrollPosition: String?
    
    func onSendMessagePressed(avatarId: String) {
        let content = textFieldText
        interactor.trackEvent(event: Event.sendMessageStart(chat: chat, avatar: avatar))
        Task {
            do {
                // Get UID
                let uid = try interactor.getAuthId()
                
                // Validate text field tex
                try TextValidationHelper.checkIfTextIsValid(text: content)
                
                // if chat is nil, then create a new chat
                if chat == nil {
                    chat = try await createNewChat(uid: uid, avatarId: avatarId)
                }
                
                // if there is no chat, throw error (should never happen)
                guard let chat else {
                    throw ChatViewError.noChat
                }
                
                // Create User chat
                let newChatMessage = AIChatModel(role: .user, content: content)
                let message = ChatMessageModel.newUserMessage( chatId: chat.id, userId: uid, message: newChatMessage)
                
                // Upload User chat
                try await interactor.addChatMessages(chatId: chat.id, message: message)
                interactor.trackEvent(event: Event.sendMessageSent(chat: chat, avatar: avatar, message: message))
                textFieldText = ""

                
                // Generate AI Response
                isGeneratingResponse = true
                var aiChats = chatMessages.compactMap({ $0.content })
                
                if let avatarDescription = avatar?.characterDescription {
                    let systemMessage = AIChatModel(
                        role: .system, content: "You are a \(avatarDescription) with the intelligence of an AI. We are having a VERY casual conversation. You are my friend."
                    )
                    aiChats.insert(systemMessage, at: 0)
                }
                
                let response = try await interactor.generateText(chats: aiChats)
                
                // Generate AI chat
                let newAIMessage = ChatMessageModel.newAIMessage( chatId: chat.id, avatarId: avatarId, message: response)
                interactor.trackEvent(event: Event.sendMessageResponse(chat: chat, avatar: avatar, message: newAIMessage))
                
                // Upload AI chat
                try await interactor.addChatMessages(chatId: chat.id, message: newAIMessage)
                interactor.trackEvent(event: Event.sendMessageResponseSent(chat: chat, avatar: avatar, message: newAIMessage))

            } catch {
                showAlert = AnyAppAlert(error: error)
            }
            isGeneratingResponse = false
        }
    }
    
    enum ChatViewError: LocalizedError {
        case noChat
    }
    
    func createNewChat(uid: String, avatarId: String) async throws -> ChatModel {
        interactor.trackEvent(event: Event.createChatStart)
        let newChat = ChatModel.new(userId: uid, avatarId: avatarId)
        try await interactor.createNewChat(chat: newChat)
        
        defer {
            Task {
                await listenForChatMessages()
            }
        }
        
        return newChat
    }
    
    func onChatSettingsPressed(onDidDeleteChat: @escaping @MainActor () -> Void) {
        interactor.trackEvent(event: Event.chatSettingsPressed)
        showChatSettings = AnyAppAlert(
            title: "",
            subtitle: "What would you like to do?",
            buttons: {
                AnyView(
                    Group {
                        Button("Report User / Chat", role: .destructive) {
                            self.onReportChatPressed()
                        }
                        Button("Delete Chat", role: .destructive) {
                            self.onDeleteChatPressed(onDidDeleteChat: onDidDeleteChat)
                        }
                    }
                )
            }
        )
    }
    
    func onReportChatPressed() {
        interactor.trackEvent(event: Event.reportChatStart)
        Task {
            do {
                let uid = try interactor.getAuthId()
                let chatId = try getChatId()
                try await interactor.reportChat(chatId: chatId, userId: uid)
                interactor.trackEvent(event: Event.reportChatSuccess)
                
                showAlert = AnyAppAlert(
                    title: "Reported!",
                    subtitle: "We will review the chat shortly. Thanks for bringing this to our attention."
                )
                
            } catch {
                interactor.trackEvent(event: Event.reportChatFail(error: error))
                showAlert = AnyAppAlert(
                    title: "Something went wrong",
                    subtitle: "Please check your connection and try again"
                )
            }
        }
    }
    
    func onDeleteChatPressed(onDidDeleteChat: @escaping @MainActor () -> Void) {
        interactor.trackEvent(event: Event.deleteChatStart)
        Task {
            do {
                let chatId = try getChatId()
                try await interactor.deleteChat(chatId: chatId)
                interactor.trackEvent(event: Event.deleteChatSuccess)
                
                onDidDeleteChat()
            } catch {
                interactor.trackEvent(event: Event.deleteChatFail(error: error))
                
                showAlert = AnyAppAlert(
                    title: "Something went wrong",
                    subtitle: "Please check your connection and try again"
                )
            }
        }
    }
    
    func onAvatarImagePressed() {
        interactor.trackEvent(event: Event.avatarImagePressed(avatar: avatar))
        showProfileModal = true
    }
    
    func getChatId() throws -> String {
        guard let chat else {
            throw ChatViewError.noChat
        }
        return chat.id
    }
    
    func listenForChatMessages() async {
        interactor.trackEvent(event: Event.loadMessagesStart)
        do {
            let chatId = try getChatId()
            for try await value in interactor.streamChatMessages(chatId: chatId) {
                
                chatMessages = value.sortedByKeyPath(keyPath: \.dateCreatedCalculated, ascending: true)
                scrollPosition = chatMessages.last?.id
            }
        } catch {
            interactor.trackEvent(event: Event.loadMessagesFail(error: error))
        }
    }
    
    func onViewFirstAppear(chat: ChatModel?) {
        self.currentUser = interactor.currentUser
        self.chat = chat
    }
    
    func loadChat(avatarId: String) async {
        interactor.trackEvent(event: Event.loadChatStart)
        do {
            let uid = try interactor.getAuthId()
            chat = try await interactor.getChat(userId: uid, avatarId: avatarId)
            interactor.trackEvent(event: Event.loadChatSuccess(chat: chat))
        } catch {
            interactor.trackEvent(event: Event.loadChatFail(error: error))
        }
    }
    
    func loadAvatar(avatarId: String) async {
        interactor.trackEvent(event: Event.loadAvatarStart)
        do {
            let avatar = try await interactor.getAvatar(id: avatarId)
            interactor.trackEvent(event: Event.loadAvatarSuccess(avatar: avatar))
            
            self.avatar = avatar
            try interactor.addRecentAvatar(avatar: avatar)
        } catch {
            interactor.trackEvent(event: Event.loadAvatarFail(error: error))
        }
    }
    
    func timestampView(date: Date) -> some View {
        Group {
            Text(date.formatted(date: .abbreviated, time: .omitted))
            +
            Text(date.formatted(date: .omitted, time: .shortened))
        }
        .foregroundStyle(.secondary)
        .font(.callout)
    }
    
    func messageIsDelayed(message: ChatMessageModel) -> Bool {
        let currentMessageDate = message.dateCreatedCalculated
        
        guard let index = chatMessages.firstIndex(where: { $0.id == message.id }),
              chatMessages.indices.contains(index - 1)
        else {
            return false
        }
        
        let previousMessageDate = chatMessages[index - 1].dateCreatedCalculated
        let timeDiff = currentMessageDate.timeIntervalSince(previousMessageDate)
        
        let threshold: TimeInterval = 60 * 45
        return timeDiff > threshold
    }
    
    func onMessageDidAppear(message: ChatMessageModel) {
        Task {
            do {
                let uid = try interactor.getAuthId()
                let chatId = try getChatId()
                guard message.hasBeenSeenBy(userId: uid) else {
                    return
                }
                try await interactor.markChatMessageAsSeen(chatId: chatId, messageId: message.id, userId: uid)
            } catch {
                interactor.trackEvent(event: Event.messageSeenFail(error: error))
            }
        }
    }
    
    func messageIsCurrentUser(message: ChatMessageModel) -> Bool {
       message.authorId == interactor.auth?.uid
    }
    
    func onProfileModalXmarkPressed() {
        self.showProfileModal = false
    }
    
    enum Event: LoggableEvent {
        
        case loadAvatarStart
        case loadAvatarSuccess(avatar: AvatarModel?)
        case loadAvatarFail(error: Error)
        case loadChatStart
        case loadChatSuccess(chat: ChatModel?)
        case loadChatFail(error: Error)
        case loadMessagesStart
        case loadMessagesFail(error: Error)
        case messageSeenFail(error: Error)
        case sendMessageStart(chat: ChatModel?, avatar: AvatarModel?)
        case sendMessageFail(error: Error)
        case sendMessageSent(chat: ChatModel?, avatar: AvatarModel?, message: ChatMessageModel)
        case sendMessageResponse(chat: ChatModel?, avatar: AvatarModel?, message: ChatMessageModel)
        case sendMessageResponseSent(chat: ChatModel?, avatar: AvatarModel?, message: ChatMessageModel)
        case createChatStart
        case chatSettingsPressed
        case reportChatStart
        case reportChatSuccess
        case reportChatFail(error: Error)
        case deleteChatStart
        case deleteChatSuccess
        case deleteChatFail(error: Error)
        case avatarImagePressed(avatar: AvatarModel?)
        
        var eventName: String {
            switch self {
            case .loadAvatarStart:          return "ChatView_LoadAvatar_Start"
            case .loadAvatarSuccess:        return "ChatView_LoadAvatar_Success"
            case .loadAvatarFail:           return "ChatView_LoadAvatar_Fail"
            case .loadChatStart:            return "ChatView_LoadChat_Start"
            case .loadChatSuccess:          return "ChatView_LoadChat_Success"
            case .loadChatFail:             return "ChatView_LoadChat_Fail"
            case .loadMessagesStart:        return "ChatView_LoadMessages_Start"
            case .loadMessagesFail:         return "ChatView_LoadMessages_Fail"
            case .messageSeenFail:          return "ChatView_MessageSeen_Fail"
            case .sendMessageStart:         return "ChatView_SendMessage_Start"
            case .sendMessageFail:          return "ChatView_SendMessage_Fail"
            case .sendMessageSent:          return "ChatView_SendMessage_Sent"
            case .sendMessageResponse:      return "ChatView_SendMessage_Response"
            case .sendMessageResponseSent:  return "ChatView_SendMessage_ResponseSent"
            case .createChatStart:          return "ChatView_CreateChat_Start"
            case .chatSettingsPressed:      return "ChatView_ChatSettings_Pressed"
            case .reportChatStart:          return "ChatView_ReportChat_Start"
            case .reportChatSuccess:        return "ChatView_ReportChat_Success"
            case .reportChatFail:           return "ChatView_ReportChat_Fail"
            case .deleteChatStart:          return "ChatView_DeleteChat_Start"
            case .deleteChatSuccess:        return "ChatView_DeleteChat_Success"
            case .deleteChatFail:           return "ChatView_DeleteChat_Fail"
            case .avatarImagePressed:       return "ChatView_AvatarImage_Pressed"
            }
        }
        
        var parameters: [String: Any]? {
            switch self {
            case .loadAvatarFail(error: let error), .loadChatFail(error: let error), .loadMessagesFail(error: let error), .messageSeenFail(error: let error), .reportChatFail(error: let error), .deleteChatFail(error: let error):
                return error.eventParameters
            case .loadAvatarSuccess(avatar: let avatar), .avatarImagePressed(avatar: let avatar):
                return avatar?.eventParameters
            case .loadChatSuccess(chat: let chat):
                return chat?.eventParameters
            case .sendMessageStart(chat: let chat, avatar: let avatar):
                var dict = chat?.eventParameters ?? [:]
                dict.merge(avatar?.eventParameters)
                return dict
            case .sendMessageSent(chat: let chat, avatar: let avatar, message: let message),
                    .sendMessageResponse(chat: let chat, avatar: let avatar, message: let message),
                    .sendMessageResponseSent(chat: let chat, avatar: let avatar, message: let message):
                var dict = chat?.eventParameters ?? [:]
                dict.merge(avatar?.eventParameters)
                dict.merge(message.eventParameters)
                return dict
            default:
                return nil
            }
        }
        
        var type: LogType {
            switch self {
            case .loadAvatarFail, .loadMessagesFail, .messageSeenFail, .reportChatFail, .deleteChatFail:
                return .severe
            case .loadChatFail, .sendMessageFail:
                return .warning
            default:
                return .analytic
            }
        }
    }
}
