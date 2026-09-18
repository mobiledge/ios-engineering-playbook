import Foundation

extension DateFormatter {
    /// Shared, cached medium-style date formatter (formatters are expensive to create).
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

extension Date {
    /// e.g. "Sep 27, 2005"
    var mediumString: String {
        DateFormatter.mediumDate.string(from: self)
    }
}
