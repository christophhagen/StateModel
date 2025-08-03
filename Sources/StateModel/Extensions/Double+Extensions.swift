import Foundation

extension Double {

    /// Treat the value as a timestamp
    var asTimeIntervalSince1970: Date {
        .init(timeIntervalSince1970: self)
    }
}
