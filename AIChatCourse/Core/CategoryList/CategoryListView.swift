//
//  CategoryListView.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 18/12/2025.
//

import SwiftUI

struct CategoryListDelegate {
    var path: Binding<[TabbarPathOption]>
    var category: CharacterOption = .alien
    var imageName: String = Constants.randomImage
}

struct CategoryListView: View {
    
    @State var viewModel: CategoryListViewModel
    let delegate: CategoryListDelegate
    
    var body: some View {
        List {
            CategoryCellView(
                title: delegate.category.plural.capitalized,
                imageName: delegate.imageName,
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
                        viewModel.onAvatarPressed(avatar: avatar, path: delegate.path)
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
            await viewModel.loadAvatars(category: delegate.category)
        }
    }
}

#Preview("Has data") {
    let container = DevPreview.shared.container
    container.register(AvatarManager.self, service: AvatarManager(service: MockAvatarService()))
    
    let builder = CoreBuilder(interactor: CoreInteractor(container: container))
    let delegate = CategoryListDelegate(path: .constant([]))
    
    return builder.categoryListView(delegate: delegate)
        .previewEnvironment()
}

#Preview("No data") {
    let container = DevPreview.shared.container
    container.register(AvatarManager.self, service: AvatarManager(service: MockAvatarService(avatars: [])))
    
    let builder = CoreBuilder(interactor: CoreInteractor(container: container))
    let delegate = CategoryListDelegate(path: .constant([]))
    
    return builder.categoryListView(delegate: delegate)
        .previewEnvironment()
}

#Preview("Slow loading") {
    let container = DevPreview.shared.container
    container.register(AvatarManager.self, service: AvatarManager(service: MockAvatarService(delay: 10)))
    
    let builder = CoreBuilder(interactor: CoreInteractor(container: container))
    let delegate = CategoryListDelegate(path: .constant([]))
    
    return builder.categoryListView(delegate: delegate)
        .previewEnvironment()
}

#Preview("Error loading") {
    let container = DevPreview.shared.container
    container.register(AvatarManager.self, service: AvatarManager(service: MockAvatarService(delay: 5, showError: true)))
    
    let builder = CoreBuilder(interactor: CoreInteractor(container: container))
    let delegate = CategoryListDelegate(path: .constant([]))
    
    return builder.categoryListView(delegate: delegate)
        .previewEnvironment()
}

