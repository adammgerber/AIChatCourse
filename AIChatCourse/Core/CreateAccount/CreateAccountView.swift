//
//  CreateAccountView.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 09/12/2025.
//

import SwiftUI

struct CreateAccountDelegate {
    var title: String = "Create Account"
    var subtitle: String = "Don't lose your data! Connect to an SSO provider to save your account."
    var onDidSignIn: ((_ isNewUser: Bool) -> Void)?
}

struct CreateAccountView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: CreateAccountViewModel
    var delegate: CreateAccountDelegate = CreateAccountDelegate()
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(delegate.title)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                Text(delegate.subtitle)
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            SignInWithAppleButtonView(
                type: .signIn,
                style: .black,
                cornerRadius: 10
            )
            .frame(height: 50)
            .anyButton(.press) {
                viewModel.onSignInApplePressed(onDidSignInSuccessfully: { isNewUser in
                    delegate.onDidSignIn?(isNewUser)
                    dismiss()
                })
            }
            
            Spacer()
        }
        .padding(16)
        .padding(.top, 40)
        .screenAppearAnalytics(name: "CreateAccountView")
    }
}

#Preview {
    CreateAccountView(viewModel: CreateAccountViewModel(interactor: CoreInteractor(container: DevPreview.shared.container)))
}
