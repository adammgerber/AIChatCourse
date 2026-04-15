//
//  AIChatCourseApp.swift
//  AIChatCourse
//
//  Created by Adam Gerber on 09/09/2025.
//

import SwiftUI
import SwiftfulUtilities

@main
struct AppEntryPoint {
    static func main() {
        if Utilities.isUnitTesting {
            TestingApp.main()
        } else {
            AIChatCourseApp.main()
        }
    }
}

struct AIChatCourseApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            AppView(viewModel: AppViewModel(interactor: CoreInteractor(container: delegate.dependencies.container)))
                .environment(CoreBuilder(interactor: CoreInteractor(container: delegate.dependencies.container)))
                .environment(delegate.dependencies.container)
                .environment(delegate.dependencies.logManager)
        }
    }
}

struct TestingApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Testing!")
        }
    }
}
