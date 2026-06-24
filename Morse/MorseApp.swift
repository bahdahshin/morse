import SwiftUI

@main
struct MorseApp: App {
    var body: some Scene {
        WindowGroup {
            TouchScreenView()
                .ignoresSafeArea()
                .persistentSystemOverlays(.hidden)
        }
    }
}
