import SwiftUI

/// Loads and displays artwork (album/poster) from a URL, with a consistent
/// placeholder and corner radius drawn from the tokens.
public struct DSArtwork: View {
    private let url: URL?
    private let size: CGFloat

    public init(url: URL?, size: CGFloat = 56) {
        self.url = url
        self.size = size
    }

    public var body: some View {
        AsyncImage(url: url) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                .fill(DSColors.surface)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
    }
}
