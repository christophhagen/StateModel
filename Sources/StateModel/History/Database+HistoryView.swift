import Foundation

extension HistoryDatabase {

    /**
     Get a view of the database at a specific instant in time.
     */
    public func view(at date: Date) -> HistoryView<ModelKey, InstanceKey, PropertyKey> {
        .init(wrapped: self, date: date)
    }
}
