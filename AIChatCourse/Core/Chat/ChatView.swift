//
//  ChatView.swift
//  AIChatCourse
//
import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: ChatViewModel
    
    var chat: ChatModel?
    var avatarId: String = AvatarModel.mock.avatarId

    var body: some View {
        VStack(spacing: 0) {
            scrollViewSection
            textFieldSection
        }
        .navigationTitle(viewModel.avatar?.name ?? "")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    if viewModel.isGeneratingResponse {
                        ProgressView()
                    }
                    
                    Image(systemName: "ellipsis")
                        .padding(8)
                        .anyButton {
                            viewModel.onChatSettingsPressed(onDidDeleteChat: {
                                dismiss()
                            })
                        }
                }
                
            }
        }
        .screenAppearAnalytics(name: "ChatView")
        .showCustomAlert(type: .confirmationDialog, alert: $viewModel.showChatSettings)
        .showCustomAlert(alert: $viewModel.showAlert)
        .showModal(showModal: $viewModel.showProfileModal) {
            if let avatar = viewModel.avatar {
                profileModal(avatar: avatar)
            }
        }
        .task {
            await viewModel.loadAvatar(avatarId: avatarId)
        }
        .task {
            await viewModel.loadChat(avatarId: avatarId)
            await viewModel.listenForChatMessages()
        }
        .onFirstAppear {
            viewModel.onViewFirstAppear(chat: chat)
        }
    }
    
    func profileModal(avatar: AvatarModel) -> some View {
        ProfileModalView(
            imageName: avatar.profileImageName,
            title: avatar.name,
            subtitle: avatar.characterOption?.rawValue.capitalized,
            headline: avatar.characterDescription,
            onXMarkPressed: {
                viewModel.onProfileModalXmarkPressed()
            }
        )
        .padding(40)
        .transition(.slide)
    }
    
    private var scrollViewSection: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(viewModel.chatMessages) { message in
                    if viewModel.messageIsDelayed(message: message) {
                        viewModel.timestampView(date: message.dateCreatedCalculated)
                    }
                    
                    let isCurrentUser = viewModel.messageIsCurrentUser(message: message)
                    ChatBubbleViewBuilder(
                        message: message,
                        isCurrentUser: isCurrentUser,
                        currentUserProfileColor: viewModel.currentUser?.profileColorCalculated ?? .accent,
                        imageName: isCurrentUser ? nil : viewModel.avatar?.profileImageName,
                        onImagePressed: viewModel.onAvatarImagePressed
                    )
                    .onAppear {
                        viewModel.onMessageDidAppear(message: message)
                    }
                    .id(message.id)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .rotationEffect(.degrees(180))
        }
        .rotationEffect(.degrees(180))
        .scrollPosition(id: $viewModel.scrollPosition, anchor: .center)
        .animation(.default, value: viewModel.chatMessages.count)
        .animation(.default, value: viewModel.scrollPosition)
    }
    
    private var textFieldSection: some View {
        TextField("Say something...", text: $viewModel.textFieldText)
            .keyboardType(.alphabet)
            .autocorrectionDisabled()
            .padding(12)
            .padding(.trailing, 60)
            .overlay(
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .padding(.trailing, 4)
                    .foregroundStyle(.accent)
                    .anyButton(.plain, action: {
                        viewModel.onSendMessagePressed(avatarId: avatarId)
                    })
                
                , alignment: .trailing
            )
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 100)
                        .fill(Color(uiColor: .systemBackground))
                    
                    RoundedRectangle(cornerRadius: 100)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                }
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(uiColor: .secondarySystemBackground))
    }
}

#Preview("Working chat") {
    NavigationStack {
        ChatView(viewModel: ChatViewModel(interactor: CoreInteractor(container: DevPreview.shared.container)))
    }
}

#Preview("Slow AI generation") {
    let container = DevPreview.shared.container
    container.register(AIManager.self, service: AIManager(service: MockAIService(delay: 20)))
    
    return NavigationStack {
        ChatView(viewModel: ChatViewModel(interactor: CoreInteractor(container: container)))
            .previewEnvironment()
    }
}

#Preview("Failed AI generation") {
    let container = DevPreview.shared.container
    container.register(AIManager.self, service: AIManager(service: MockAIService(delay: 2, showError: true)))
    
    return NavigationStack {
        ChatView(viewModel: ChatViewModel(interactor: CoreInteractor(container: container)))
            .previewEnvironment()
    }
}
