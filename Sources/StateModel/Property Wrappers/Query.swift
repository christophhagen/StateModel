import SwiftUI

public enum QuerySortOrder {
    case ascending
    case descending
}

@MainActor
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@propertyWrapper
public struct Query<Result: ModelProtocol>: @MainActor DynamicProperty {

    @EnvironmentObject
    private var database: ObservableDatabase

    @StateObject
    private var observer: QueryManager<Result>

    /**
     Create a query to dynamically observe instances.
     - Parameter isIncluded: Optional closure to filter instances
     - Parameter areInIncreasingOrder: Optional closure to sort the instances
     */
    public init(filter isIncluded: ((Result) -> Bool)? = nil, sort areInIncreasingOrder: ((Result, Result) -> Bool)? = nil) {
        let observer = QueryManager<Result>(database: nil, filter: isIncluded, order: areInIncreasingOrder)
        _observer = StateObject(wrappedValue: observer)
    }

    /**
     Create a query to dynamically observe instances.
     - Parameter isIncluded: Optional closure to filter instances
     - Parameter order: The sort ordering for the instances
     - Parameter transform: Transform each instance to a value that is used for sorting
     */
    public init<T: Comparable>(filter isIncluded: ((Result) -> Bool)? = nil, sort order: QuerySortOrder, using transform: @escaping (Result) -> T) {
        switch order {
        case .ascending:
            self.init(filter: isIncluded, sort: { transform($0) < transform($1) })
        case .descending:
            self.init(filter: isIncluded, sort: { transform($0) > transform($1) })
        }
    }

    /**
     Create a query to dynamically observe instances.
     - Parameter isIncluded: Optional closure to filter instances
     - Parameter transform: Transform each instance to a value that is used for sorting
     */
    public init<T: Comparable>(filter isIncluded: ((Result) -> Bool)? = nil, sortBy transform: @escaping (Result) -> T) {
        self.init(filter: isIncluded, sort: .ascending, using: transform)
    }

    public var wrappedValue: [Result] {
        observer.results
    }

    mutating public func update() {
        observer.update(database: database)
    }
}
