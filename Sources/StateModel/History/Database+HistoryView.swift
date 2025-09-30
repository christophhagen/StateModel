import Foundation

extension HistoryDatabase {

    /**
     Get a view of the database at a specific instant in time.
     - Parameter date: The instant in time for which to view the database
     - Returns: The view of the database at the given date
     */
    public func view(at date: Date) -> HistoryView {
        .init(wrapped: self, at: date)
    }
}
