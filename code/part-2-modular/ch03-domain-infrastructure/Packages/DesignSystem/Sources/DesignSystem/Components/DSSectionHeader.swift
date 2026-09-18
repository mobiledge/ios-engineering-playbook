import SwiftUI

/// A simple section header with an optional trailing accessory.
public struct DSSectionHeader<Accessory: View>: View {
    private let title: String
    private let accessory: Accessory

    public init(_ title: String, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.accessory = accessory()
    }

    public var body: some View {
        HStack {
            DSText(title, style: .headline)
            Spacer()
            accessory
        }
    }
}

public extension DSSectionHeader where Accessory == EmptyView {
    init(_ title: String) {
        self.init(title, accessory: { EmptyView() })
    }
}
