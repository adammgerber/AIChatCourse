//
//  AppDelegate.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 13/04/2026.
//
import SwiftUI
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    
    var dependencies: Dependencies!
    var builder: CoreBuilder!
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        let config: BuildConfiguration
        
        #if MOCK
        config = .mock(isSignedIn: true)
        #elseif DEV
        config = .dev
        #else
        config = .prod
        #endif
      
        config.configure()
        dependencies = Dependencies(config: config)
        builder = CoreBuilder(interactor: CoreInteractor(container: dependencies.container))
        return true
    }
}

enum BuildConfiguration {
    case mock(isSignedIn: Bool), dev, prod
    
    func configure() {
        switch self {
            
        case .mock:
            // does not run firebase
            break
        case .dev:
            let plist = Bundle.main.path(forResource: "GoogleService-Info-Dev", ofType: "plist")!
            let options = FirebaseOptions(contentsOfFile: plist)!
            FirebaseApp.configure(options: options)
        case .prod:
            let plist = Bundle.main.path(forResource: "GoogleService-Info-Prod", ofType: "plist")!
            let options = FirebaseOptions(contentsOfFile: plist)!
            FirebaseApp.configure(options: options)
        }
    }
}
