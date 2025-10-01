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

    public init() {
        let observer = QueryManager<Result>(database: nil)
        _observer = StateObject(wrappedValue: observer)
    }

    public init(filter: @escaping (Result) -> Bool) {
        let observer = QueryManager<Result>(database: nil, filter: filter)
        _observer = StateObject(wrappedValue: observer)
    }

    public init(filter: @escaping (Result) -> Bool, sort: @escaping (Result, Result) -> Bool) {
        let observer = QueryManager<Result>(database: nil, filter: filter, order: sort)
        _observer = StateObject(wrappedValue: observer)
    }

    public init(sort: @escaping (Result, Result) -> Bool) {
        let observer = QueryManager<Result>(database: nil, filter: nil, order: sort)
        _observer = StateObject(wrappedValue: observer)
    }

    public init<T: Comparable>(sort order: QuerySortOrder = .ascending, using: @escaping (Result) -> T) {
        let sort: (Result, Result) -> Bool
        switch order {
        case .ascending: sort = { using($0) < using($1) }
        case .descending: sort = { using($0) > using($1) }
        }
        let observer = QueryManager<Result>(database: nil, filter: nil, order: sort)
        _observer = StateObject(wrappedValue: observer)
    }

    public init<T: Comparable>(filter: @escaping (Result) -> Bool, sort order: QuerySortOrder = .ascending, using: @escaping (Result) -> T) {
        let sort: (Result, Result) -> Bool
        switch order {
        case .ascending: sort = { using($0) < using($1) }
        case .descending: sort = { using($0) > using($1) }
        }
        let observer = QueryManager<Result>(database: nil, filter: filter, order: sort)
        _observer = StateObject(wrappedValue: observer)
    }

    public var wrappedValue: [Result] {
        observer.results
    }

    mutating public func update() {
        observer.update(database: database)
    }
}
