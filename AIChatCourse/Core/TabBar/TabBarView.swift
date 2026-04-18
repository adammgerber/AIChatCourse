//
//  TabBarView.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 02/12/2025.
//

import SwiftUI

struct TabBarView: View {
    
    @Environment(CoreBuilder.self) private var builder
    
    var body: some View {
        TabView {
            builder.exploreView()
                .tabItem {
                    Label("Explore", systemImage: "eyes")
                }
            builder.chatsView()
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right.fill")
                }
            builder.profileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    TabBarView()
        .previewEnvironment()
}
