import SwiftUI

@main
struct ProjectApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate


    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
    }
}
