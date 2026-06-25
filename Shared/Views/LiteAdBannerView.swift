#if LITE_VERSION && os(iOS)
import GoogleMobileAds
import SwiftUI
import UIKit

struct LiteAdBannerView: View {
    var body: some View {
        BannerViewRepresentable(adSize: AdSizeBanner)
            .frame(width: AdSizeBanner.size.width, height: AdSizeBanner.size.height)
            .frame(maxWidth: .infinity)
            .frame(height: AdSizeBanner.size.height)
        .accessibilityHidden(true)
    }
}

private let liteBannerAdUnitID = {
    #if DEBUG
    "ca-app-pub-3940256099942544/2934735716"
    #else
    "ca-app-pub-5813365636393784/1541829296"
    #endif
}()

private struct BannerViewRepresentable: UIViewRepresentable {
    let adSize: AdSize

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: adSize)
        bannerView.adUnitID = liteBannerAdUnitID
        bannerView.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ bannerView: BannerView, context: Context) {
        bannerView.adSize = adSize
    }
}
#endif
