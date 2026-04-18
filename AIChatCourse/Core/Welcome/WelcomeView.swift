//
//  WelcomeView.swift
//  AIChatCourse
//
//  Created by Nick Sarno on 10/5/24.
//

import SwiftUI

struct WelcomeView: View {
    
    @Environment(CoreBuilder.self) private var builder
    @State var viewModel: WelcomeViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                ImageLoaderView(urlString: viewModel.imageName)
                    .ignoresSafeArea()
                
                titleSection
                    .padding(.top, 24)
                
                ctaButtons
                    .padding(16)
                
                policyLinks
            }
        }
        .screenAppearAnalytics(name: "WelcomeView")
        .sheet(isPresented: $viewModel.showSignInView) {
            builder.createAccountView(
                delegate: CreateAccountDelegate(
                    title: "Sign in",
                    subtitle: "Connect to an existing account.",
                    onDidSignIn: { isNewUser in
                        viewModel.handleDidSignIn(isNewUser: isNewUser)
                    }
                )
            )
            .presentationDetents([.medium])
        }
    }
    
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("AI Chat 🤙")
                .font(.largeTitle)
                .fontWeight(.semibold)
            
            Text("YouTube @ SwiftfulThinking")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var ctaButtons: some View {
        VStack(spacing: 8) {
            Text("Get Started")
                .callToActionButton()
                .anyButton(.press, action: {
                    viewModel.onGetStartedPressed()
                })
            
            Text("Already have an account? Sign in!")
                .underline()
                .font(.body)
                .padding(8)
                .tappableBackground()
                .onTapGesture {
                    viewModel.onSignInPresssed()
                }
        }
    }
    
    private var policyLinks: some View {
        HStack(spacing: 8) {
            Link(destination: URL(string: Constants.termsOfServiceUrl)!) {
                Text("Terms of Service")
            }
            Circle()
                .fill(.accent)
                .frame(width: 4, height: 4)
            Link(destination: URL(string: Constants.privacyPolicyUrl)!) {
                Text("Privacy Policy")
            }
        }
    }
}

#Preview {
    let builder = CoreBuilder(interactor: CoreInteractor(container: DevPreview.shared.container))
    return builder.welcomeView()
        .previewEnvironment()
}
