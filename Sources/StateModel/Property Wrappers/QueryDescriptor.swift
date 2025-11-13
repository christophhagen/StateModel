#if canImport(SwiftUI)

public struct QueryDescriptor<Result: ModelProtocol> {

    let id: Int

    let isIncluded: ((Result) -> Bool)?

    let areInIncreasingOrder: ((Result, Result) -> Bool)?

    /**
     Create a descriptor to configure a query.
     - Parameter isIncluded: Optional closure to filter instances
     - Parameter areInIncreasingOrder: Optional closure to sort the instances
     */
    public init(filter isIncluded: ((Result) -> Bool)? = nil,
                sort areInIncreasingOrder: ((Result, Result) -> Bool)? = nil) {
        self.id = .random(in: Int.min...Int.max)
        self.isIncluded = isIncluded
        self.areInIncreasingOrder = areInIncreasingOrder
    }

    /**
     Create a descriptor to configure a query.
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
     Create a descriptor to configure a query.
     - Parameter isIncluded: Optional closure to filter instances
     - Parameter transform: Transform each instance to a value that is used for sorting
     */
    public init<T: Comparable>(filter isIncluded: ((Result) -> Bool)? = nil, sortBy transform: @escaping (Result) -> T) {
        self.init(filter: isIncluded, sort: .ascending, using: transform)
    }
}

extension QueryDescriptor: Equatable {

    public static func == (lhs: QueryDescriptor<Result>, rhs: QueryDescriptor<Result>) -> Bool {
        lhs.id == rhs.id
    }
}

#endif
