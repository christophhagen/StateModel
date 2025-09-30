import SwiftUI

@MainActor
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@propertyWrapper
public struct Query<Result: ModelProtocol>: @MainActor DynamicProperty {

    @EnvironmentObject
    private var database: ObservableDatabase

    @StateObject
    private var observer: QueryManager<Result> = .init(database: nil)

    public init() { }

    public var wrappedValue: [Result] {
        observer.results
    }

    mutating public func update() {
        observer.update(database: database)
    }
}
