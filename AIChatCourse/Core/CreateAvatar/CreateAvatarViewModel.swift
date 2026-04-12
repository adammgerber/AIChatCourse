//
//  CreateAvatarViewModel.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 12/04/2026.
//

import SwiftUI

@MainActor
protocol CreateAvatarInteractor {
    func trackEvent(event: LoggableEvent)
    func getAuthId() throws -> String
    func generateImage(input: String) async throws -> UIImage
    func createAvatar(avatar: AvatarModel, image: UIImage) async throws
}

extension CoreInteractor: CreateAvatarInteractor {}

@Observable
@MainActor
class CreateAvatarViewModel {
    
    private let interactor: CreateAvatarInteractor
    
    init(interactor: CreateAvatarInteractor) {
        self.interactor = interactor
    }

    private(set) var isGenerating: Bool = false
    private(set) var isSaving: Bool = false
    private(set) var generatedImage: UIImage?
    
    var characterOption: CharacterOption = .default
    var characterAction: CharacterAction = .default
    var characterLocation: CharacterLocation = .default
    var showAlert: AnyAppAlert?
    var avatarName: String = ""
    
    
    func onBackButtonPressed(onDismiss: () -> Void) {
        interactor.trackEvent(event: Event.backButtonPressed)
        onDismiss()
    }
    
    func onGenerateImagePressed() {
        isGenerating = true
        interactor.trackEvent(event: Event.backButtonPressed)

        Task {
            do {
                let avatarDescriptionBuilder = AvatarDescriptionBuilder(
                    characterOption: characterOption,
                    characterAction: characterAction,
                    characterLocation: characterLocation
                )
                let prompt = avatarDescriptionBuilder.characterDescription
                
                generatedImage = try await interactor.generateImage(input: prompt)
                interactor.trackEvent(event: Event.generateImageSuccess(avatarDescriptionBuilder: avatarDescriptionBuilder))

            } catch {
                interactor.trackEvent(event: Event.generateImageFail(error: error))
            }
            
            isGenerating = false
        }
    }
    
    func onSavePressed(onDismiss: @escaping () -> Void) {
        interactor.trackEvent(event: Event.saveAvatarStart)
        guard let generatedImage else { return }

        isSaving = true
        
        Task {
            do {
                try TextValidationHelper.checkIfTextIsValid(text: avatarName, minimumCharacterCount: 3)
                let uid = try interactor.getAuthId()
                
                let avatar = AvatarModel.newAvatar(
                    name: avatarName,
                    option: characterOption,
                    action: characterAction,
                    location: characterLocation,
                    authorId: uid
                )

                try await interactor.createAvatar(avatar: avatar, image: generatedImage)
                interactor.trackEvent(event: Event.saveAvatarSuccess(avatar: avatar))

                // Dismiss screen
                onDismiss()
            } catch {
                showAlert = AnyAppAlert(error: error)
                interactor.trackEvent(event: Event.saveAvatarFail(error: error))
            }
            
            isSaving = false
        }
    }
    
    enum Event: LoggableEvent {
        case backButtonPressed
        case generateImageStart
        case generateImageSuccess(avatarDescriptionBuilder: AvatarDescriptionBuilder)
        case generateImageFail(error: Error)
        case saveAvatarStart
        case saveAvatarSuccess(avatar: AvatarModel)
        case saveAvatarFail(error: Error)

        var eventName: String {
            switch self {
            case .backButtonPressed:         return "CreateAvatarView_BackButton_Pressed"
            case .generateImageStart:        return "CreateAvatarView_GenImage_Start"
            case .generateImageSuccess:      return "CreateAvatarView_GenImage_Success"
            case .generateImageFail:         return "CreateAvatarView_GenImage_Fail"
            case .saveAvatarStart:           return "CreateAvatarView_SaveAvatar_Start"
            case .saveAvatarSuccess:         return "CreateAvatarView_SaveAvatar_Success"
            case .saveAvatarFail:            return "CreateAvatarView_SaveAvatar_Fail"
            }
        }
        
        var parameters: [String: Any]? {
            switch self {
            case .generateImageSuccess(avatarDescriptionBuilder: let avatarDescriptionBuilder):
                return avatarDescriptionBuilder.eventParameters
            case .saveAvatarSuccess(avatar: let avatar):
                return avatar.eventParameters
            case .generateImageFail(error: let error), .saveAvatarFail(error: let error):
                return error.eventParameters
            default:
                return nil
            }
        }
        
        var type: LogType {
            switch self {
            case .generateImageFail:
                return .severe
            case .saveAvatarFail:
                return .warning
            default:
                return .analytic
            }
        }
    }
    
}
