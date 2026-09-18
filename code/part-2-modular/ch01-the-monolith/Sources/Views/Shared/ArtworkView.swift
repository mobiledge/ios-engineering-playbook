import SwiftUI

/// Loads and displays album / poster artwork from a URL.
struct ArtworkView: View {
    let url: URL?
    var size: CGFloat = 56

    var body: some View {
        AsyncImage(url: url) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .fill(AppColor.surface)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
    }
}
