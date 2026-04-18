//
//  ProfileView.swift
//  AIChatCourse
//
//  Created by Nick Sarno on 10/5/24.
//

import SwiftUI

struct ProfileView: View {
    
    @Environment(CoreBuilder.self) private var builder
    @State var viewModel: ProfileViewModel
    
    var body: some View {
        NavigationStack(path: $viewModel.path) {
            List {
                myInfoSection
                myAvatarsSection
            }
            .navigationTitle("Profile")
            .navigationDestinationForTabbarModule(path: $viewModel.path)
            .showCustomAlert(alert: $viewModel.showAlert)
            .screenAppearAnalytics(name: "ProfileView")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    settingsButton
                }
            }
        }
        .sheet(isPresented: $viewModel.showSettingsView) {
            builder.settingsView()
        }
        .fullScreenCover(
            isPresented: $viewModel.showCreateAvatarView,
            onDismiss: {
                Task {
                    await viewModel.loadData()
                }
            },
            content: {
                builder.createAvatarView()
            })
        .task {
            await viewModel.loadData()
        }
    }
    
    private var myInfoSection: some View {
        Section {
            ZStack {
                Circle()
                    .fill(viewModel.currentUser?.profileColorCalculated ?? .accent)
            }
            .frame(width: 100, height: 100)
            .frame(maxWidth: .infinity)
            .removeListRowFormatting()
        }
    }
    
    private var myAvatarsSection: some View {
        Section {
            if viewModel.myAvatars.isEmpty {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Click + to create an avatar")
                    }
                }
                .padding(50)
                .frame(maxWidth: .infinity)
                .font(.body)
                .foregroundStyle(.secondary)
                .removeListRowFormatting()
            } else {
                ForEach(viewModel.myAvatars, id: \.self) { avatar in
                    CustomListCellView(
                        imageName: avatar.profileImageName,
                        title: avatar.name,
                        subtitle: nil
                    )
                    .anyButton(.highlight, action: {
                        viewModel.onAvatarPressed(avatar: avatar)
                    })
                    .removeListRowFormatting()
                }
                .onDelete { indexSet in
                    viewModel.onDeleteAvatar(indexSet: indexSet)
                }
            }
        } header: {
            HStack(spacing: 0) {
                Text("My avatars")
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundStyle(.accent)
                    .anyButton {
                        viewModel.onNewAvatarButtonPressed()
                    }
            }
        }
    }
    
    private var settingsButton: some View {
        Image(systemName: "gear")
            .font(.headline)
            .foregroundStyle(.accent)
            .anyButton {
                viewModel.onSettingsButtonPressed()
            }
    }
}

#Preview {
    let builder = CoreBuilder(interactor: CoreInteractor(container: DevPreview.shared.container))
    
    return builder.profileView()
    .previewEnvironment()
}
