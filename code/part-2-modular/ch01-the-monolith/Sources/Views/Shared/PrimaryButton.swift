import SwiftUI

/// A reusable, brand-colored call-to-action button.
struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title).font(AppFont.callout)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .foregroundStyle(AppColor.onBrand)
            .background(AppColor.brand)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
