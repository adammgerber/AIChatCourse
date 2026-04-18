//
//  ChatRowCellViewBuilder.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 08/12/2025.
//

import SwiftUI

struct ChatRowCellDelegate {
    var chat: ChatModel = .mock
}

struct ChatRowCellViewBuilder: View {
    
    @State var viewModel: ChatRowCellViewModel
    let delegate: ChatRowCellDelegate
    
    var body: some View {
        ChatRowCellView(
            imageName: viewModel.avatar?.profileImageName,
            headline: viewModel.isLoading ? "xxxx xxxx" : viewModel.avatar?.name,
            subheadline: viewModel.subheadline,
            hasNewChat: viewModel.isLoading ? false : viewModel.hasNewChat
        )
        .redacted(reason: viewModel.isLoading ? .placeholder : [])
        .task {
            await viewModel.loadAvatar(chat: delegate.chat)
        }
        .task {
            await viewModel.loadLastChatMessage(chat: delegate.chat)
        }
    }
}

#Preview {
    let builder = CoreBuilder(interactor: CoreInteractor(container: DevPreview.shared.container))
    
    return VStack {
        builder.chatRowCell()
        
        
//        ChatRowCellViewBuilder(chat: .mock, getAvatar: {
//            try? await Task.sleep(for: .seconds(5))
//            return .mock
//        }, getLastChatMessage: {
//            try? await Task.sleep(for: .seconds(5))
//            return .mock
//        })
//        
//        ChatRowCellViewBuilder(chat: .mock, getAvatar: {
//            .mock
//        }, getLastChatMessage: {
//            .mock
//        })
//        ChatRowCellViewBuilder(chat: .mock, getAvatar: {
//            nil
//        }, getLastChatMessage: {
//            nil
//        })
        
    }
}
