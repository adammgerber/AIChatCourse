//
//  CategoryListView.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 18/12/2025.
//

import SwiftUI

struct CategoryListView: View {
    
    @State var viewModel: CategoryListViewModel
  
    @Binding var path: [NavigationPathOption]
    var category: CharacterOption = .alien
    var imageName: String = Constants.randomImage
   
    var body: some View {
        List {
            CategoryCellView(
                title: category.plural.capitalized,
                imageName: imageName,
                font: .largeTitle,
                cornerRadius: 0
            )
            .removeListRowFormatting()
            
            if viewModel.avatars.isEmpty && viewModel.isLoading {
                ProgressView()
                    .padding(40)
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                    .removeListRowFormatting()
            } else {
                ForEach(viewModel.avatars, id: \.self) { avatar in
                    CustomListCellView(
                        imageName: avatar.profileImageName,
                        title: avatar.name,
                        subtitle: avatar.characterDescription
                    )
                    .anyButton(.highlight) {
                        viewModel.onAvatarPressed(avatar: avatar, path: $path)
                    }
                    .removeListRowFormatting()
                }
            }
        }
        .showCustomAlert(alert: $viewModel.showAlert)
        .screenAppearAnalytics(name: "CategoryList")
        .ignoresSafeArea()
        .listStyle(PlainListStyle())
        .task {
            await viewModel.loadAvatars(category: category)
        }
    }
}

#Preview("Has data") {
    let container = DevPreview.shared.container
    container.register(AvatarManager.self, service: AvatarManager(service: MockAvatarService()))
    
    return CategoryListView(viewModel: CategoryListViewModel(interactor: CoreInteractor(container: container)), path: .constant([]))
        .environment(AvatarManager(service: MockAvatarService()))
        .previewEnvironment()
}

#Preview("No data") {
    let container = DevPreview.shared.container
    container.register(AvatarManager.self, service: AvatarManager(service: MockAvatarService(avatars: [])))
    
    return CategoryListView(viewModel: CategoryListViewModel(interactor: CoreInteractor(container: container)), path: .constant([]))
        .environment(AvatarManager(service: MockAvatarService()))
        .previewEnvironment()
}

#Preview("Slow loading") {
    let container = DevPreview.shared.container
    container.register(AvatarManager.self, service: AvatarManager(service: MockAvatarService(delay: 10)))
    
    return CategoryListView(viewModel: CategoryListViewModel(interactor: CoreInteractor(container: container)), path: .constant([]))
        .environment(AvatarManager(service: MockAvatarService()))
        .previewEnvironment()
}

#Preview("Error loading") {
    let container = DevPreview.shared.container
    container.register(AvatarManager.self, service: AvatarManager(service: MockAvatarService(delay: 5, showError: true)))
    
    return CategoryListView(viewModel: CategoryListViewModel(interactor: CoreInteractor(container: container)), path: .constant([]))
        .environment(AvatarManager(service: MockAvatarService()))
        .previewEnvironment()
}

