import Foundation


extension HistoryDatabase {

    /**
     Create a new context to make edits.
     */
    public func createEditingContext() -> EditingContext<ModelKey, InstanceKey, PropertyKey> {
        .init(database: self, date: Date())
    }
}
