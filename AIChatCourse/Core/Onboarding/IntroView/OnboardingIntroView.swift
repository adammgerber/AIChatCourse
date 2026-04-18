//
//  OnboardingIntroView.swift
//  AIChatCourse
//
//  Created by Nick Sarno on 10/6/24.
//

import SwiftUI

struct OnboardingIntroDelegate {
    var path: Binding<[OnboardingPathOption]>
}

struct OnboardingIntroView: View {
    @Environment(CoreBuilder.self) private var builder
    @State var viewModel: OnboardingIntroViewModel
    var delegate: OnboardingIntroDelegate
    
    var body: some View {
        VStack {
            Group {
                Text("Make your own ")
                +
                Text("avatars ")
                    .foregroundStyle(.accent)
                    .fontWeight(.semibold)
                +
                Text("and chat with them!\n\nHave ")
                +
                Text("real conversations ")
                    .foregroundStyle(.accent)
                    .fontWeight(.semibold)
                +
                Text("with AI generated responses.")
            }
            .baselineOffset(6)
            .frame(maxHeight: .infinity)
            .padding(24)

            Text("Continue")
                .callToActionButton()
                .anyButton(.press) {
                    viewModel.onContinueButtonPressed(path: delegate.path)
                }
        }
        .padding(24)
        .font(.title3)
        .toolbar(.hidden, for: .navigationBar)
        .screenAppearAnalytics(name: "OnboardingIntroView")
    }
}

#Preview("Original") {
    let container = DevPreview.shared.container
    let builder = CoreBuilder(interactor: CoreInteractor(container: container))
    
    return NavigationStack {
        builder.onboardingIntroView(delegate: OnboardingIntroDelegate(path: .constant([])))
    }
    .previewEnvironment()
}
