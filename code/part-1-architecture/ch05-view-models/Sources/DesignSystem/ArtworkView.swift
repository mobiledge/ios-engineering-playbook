import SwiftUI

/// A square artwork thumbnail. Knows nothing about tracks: give it a URL, or `nil`.
///
/// A gray box while the image loads; a music note when there is no artwork at all.
struct ArtworkView: View {
    let url: URL?

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
            } else {
                Image(systemName: "music.note")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.2))
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(.rect(cornerRadius: 6))
    }
}

#Preview("Artwork, missing, still loading") {
    HStack(spacing: 12) {
        ArtworkView(url: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/07/60/ba/0760ba0f-148c-b18f-d0ff-169ee96f3af5/634904078164.png/100x100bb.jpg"))
        ArtworkView(url: nil)
        // A URL that never answers: this is what "still loading" looks like.
        ArtworkView(url: URL(string: "https://example.invalid/artwork.jpg"))
    }
    .padding()
}
