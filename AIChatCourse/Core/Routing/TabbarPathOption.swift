//
//  TabbarPathOption.swift
//  AIChatCourse
//
//  Created by Nick Sarno on 10/12/24.
//
import SwiftUI
import Foundation

enum TabbarPathOption: Hashable {
    case chat(avatarId: String, chat: ChatModel?)
    case category(category: CharacterOption, imageName: String)
}

struct NavDestForTabbarModuleViewModifier: ViewModifier {
    
    @Environment(CoreBuilder.self) private var builder
    let path: Binding<[TabbarPathOption]>
    
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: TabbarPathOption.self) { newValue in
                switch newValue {
                case .chat(avatarId: let avatarId, chat: let chat):
                    builder
                        .chatView(
                            delegate: ChatViewDelegate(
                                chat: chat,
                                avatarId: avatarId
                            )
                        )
                case .category(category: let category, imageName: let imageName):
                    builder
                        .categoryListView(
                            delegate: CategoryListDelegate(
                                path: path,
                                category: category,
                                imageName: imageName
                            )
                        )
                }
            }
    }
}

extension View {
    
    func navigationDestinationForTabbarModule(path: Binding<[TabbarPathOption]>) -> some View {
        modifier(NavDestForTabbarModuleViewModifier(path: path))
    }
}
