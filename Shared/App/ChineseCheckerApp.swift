import SwiftUI
#if LITE_VERSION && os(iOS)
import AppTrackingTransparency
import GoogleMobileAds
#endif

@main
struct ChineseCheckerApp: App {
    #if LITE_VERSION && os(iOS)
    init() {
        requestAdTrackingAuthorizationAndStartAds()
    }

    private func requestAdTrackingAuthorizationAndStartAds() {
        guard #available(iOS 14, *) else {
            MobileAds.shared.start()
            return
        }

        let startAds = {
            DispatchQueue.main.async {
                MobileAds.shared.start()
            }
        }

        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                ATTrackingManager.requestTrackingAuthorization { _ in
                    startAds()
                }
            }
        } else {
            startAds()
        }
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
