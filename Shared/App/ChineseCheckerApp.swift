import SwiftUI
#if LITE_VERSION && os(iOS)
import GoogleMobileAds
#endif

@main
struct ChineseCheckerApp: App {
    #if LITE_VERSION && os(iOS)
    init() {
        MobileAds.shared.start()
    }
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowResizability(.contentMinSize)
        #endif
    }
}
