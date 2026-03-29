import Foundation


extension Database {

    /**
     Create a new context to make edits, which can be commited together.

     - Note: Updates to the database while editing will appear in the context.
     */
    public func createEditingContext() -> EditingContext {
        .init(database: self)
    }

    /**
     Get an instance from a different database in this database.
     - Parameter instance: The instance to transfer to this context
     - Returns: A reference to the instance in the current database, if it exists.
     */
    public func resolve<Instance: ModelProtocol>(_ instance: Instance) -> Instance? {
        get(id: instance.id)
    }
}

extension HistoryDatabase {

    /**
     Create a new context to make edits based on the current database state.
     - Note: Updates to the database while editing will not appear in the context.
     Commiting changes to the database will save all values,
     but only the most recent values for each property will be shown.
     */
    public func createEditingContextWithCurrentState() -> HistoryEditingContext {
        .init(database: self, date: Date())
    }
}
