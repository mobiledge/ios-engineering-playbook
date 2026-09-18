import SwiftUI
import DesignSystem

/// Showcases the design system's tokens and components on one scrollable screen.
struct CatalogView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Colors") { colors }
                Section("Typography") { typography }
                Section("Buttons") { buttons }
                Section("Tags") { tags }
                Section("Card") { card }
                Section("Section Header") { sectionHeader }
                Section("Media Row") { mediaRows }
            }
            .navigationTitle("Design System")
        }
        .tint(DSColors.brand)
    }

    // MARK: - Colors

    private var colors: some View {
        let swatches: [(String, Color)] = [
            ("brand", DSColors.brand),
            ("brandSecondary", DSColors.brandSecondary),
            ("surface", DSColors.surface),
            ("success", DSColors.success),
            ("danger", DSColors.danger)
        ]
        return ForEach(swatches, id: \.0) { name, color in
            HStack(spacing: DSSpacing.md) {
                RoundedRectangle(cornerRadius: DSRadius.sm)
                    .fill(color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: DSRadius.sm)
                            .strokeBorder(DSColors.separator)
                    )
                DSText(name, style: .body)
            }
        }
    }

    // MARK: - Typography

    private var typography: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            DSText("Large Title", style: .largeTitle)
            DSText("Title", style: .title)
            DSText("Headline", style: .headline)
            DSText("Body", style: .body)
            DSText("Callout", style: .callout)
            DSText("Caption", style: .caption)
        }
        .padding(.vertical, DSSpacing.xs)
    }

    // MARK: - Buttons

    private var buttons: some View {
        VStack(spacing: DSSpacing.md) {
            DSButton("Primary Action", systemImage: "plus", style: .primary) {}
            DSButton("Secondary Action", systemImage: "checkmark", style: .secondary) {}
        }
        .padding(.vertical, DSSpacing.xs)
    }

    // MARK: - Tags

    private var tags: some View {
        HStack(spacing: DSSpacing.sm) {
            DSTag("Pop")
            DSTag("New", color: DSColors.success)
            DSTag("Sale", color: DSColors.danger)
        }
    }

    // MARK: - Card

    private var card: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                DSText("Card Title", style: .headline)
                DSText("Cards group related content on a raised surface.", style: .callout)
            }
        }
        .padding(.vertical, DSSpacing.xs)
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        DSSectionHeader("Recently Played") {
            DSText("See All", style: .callout, color: DSColors.brand)
        }
        .padding(.vertical, DSSpacing.xs)
    }

    // MARK: - Media Row

    private var mediaRows: some View {
        VStack {
            DSMediaRow(
                title: "Banana Pancakes",
                subtitle: "Jack Johnson",
                caption: "Mar 1, 2005",
                artworkURL: nil
            ) {
                Image(systemName: "plus.circle")
                    .foregroundStyle(DSColors.brand)
                    .imageScale(.large)
            }
            DSMediaRow(
                title: "The Shining",
                subtitle: "Horror",
                artworkURL: nil
            )
        }
    }
}

#Preview {
    CatalogView()
}
