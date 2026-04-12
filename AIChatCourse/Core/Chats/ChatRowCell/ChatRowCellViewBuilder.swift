//
//  ChatRowCellViewBuilder.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 08/12/2025.
//

import SwiftUI

struct ChatRowCellViewBuilder: View {
    
    @State var viewModel: ChatRowCellViewModel
    var chat: ChatModel = .mock
    
    var body: some View {
        ChatRowCellView(
            imageName: viewModel.avatar?.profileImageName,
            headline: viewModel.isLoading ? "xxxx xxxx" : viewModel.avatar?.name,
            subheadline: viewModel.subheadline,
            hasNewChat: viewModel.isLoading ? false : viewModel.hasNewChat
        )
        .redacted(reason: viewModel.isLoading ? .placeholder : [])
        .task {
            await viewModel.loadAvatar(chat: chat)
        }
        .task {
            await viewModel.loadLastChatMessage(chat: chat)
        }
    }
}

#Preview {
    VStack {
        ChatRowCellViewBuilder(
            viewModel: ChatRowCellViewModel(
                interactor: CoreInteractor(
                    container: DevPreview.shared.container
                )
            ),
            chat: .mock
        )
//        ChatRowCellViewBuilder(chat: .mock, getAvatar: {
//            try? await Task.sleep(for: .seconds(5))
//            return .mock
//        }, getLastChatMessage: {
//            try? await Task.sleep(for: .seconds(5))
//            return .mock
//        })
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
