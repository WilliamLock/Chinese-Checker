#if LITE_VERSION && os(iOS)
import GoogleMobileAds
import SwiftUI
import UIKit

struct LiteAdBannerView: View {
    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 320)
            let adSize = currentOrientationAnchoredAdaptiveBanner(width: width)

            BannerViewRepresentable(adSize: adSize)
                .frame(width: adSize.size.width, height: adSize.size.height)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 60)
        .accessibilityHidden(true)
    }
}

private struct BannerViewRepresentable: UIViewRepresentable {
    let adSize: AdSize

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: adSize)
        bannerView.adUnitID = "ca-app-pub-5813365636393784/1541829296"
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
