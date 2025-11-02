import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import Testing
import StateModel

@Model(id: 2)
public class PublicModel {

    @Property(id: 1)
    public var a: Int
}

@Model(id: 3)
private class PrivateModel {

    @Property(id: 1)
    public var a: Int
}

@Model(id: 4)
internal final class InternalModel {

    @Property(id: 1)
    internal var a: Int
}

#if canImport(StateModelMacros)
import StateModelMacros

nonisolated(unsafe) private let testMacros: [String: Macro.Type] = [
    "Model" : ModelMacro.self
]
#endif

final class AccessModifierTests: XCTestCase {

    func testGeneratePublicModel() throws {
    #if canImport(StateModelMacros)
        assertMacroExpansion(
            """
            @Model(id: 1)
            public final class PublicModel {

                @Property(id: 1)
                var some: Int = 1
            }
            """,
            expandedSource:
            """
            public final class PublicModel {

                @Property(id: 1)
                var some: Int = 1

                /**
                 The unique id of this model in the database.
                 */
                public static let modelId: ModelKey = 1

                /// The reference to the database to which this object is linked
                public unowned let database: Database

                /// The unique id of the instance
                public let id: InstanceKey

                /**
                 Create a model.
                 - Parameter database: The reference to the model database to read and write property values
                 - Parameter id: The unique id of the instance
                 - Note: This initializer should never be used directly. Create object through the database functions
                 */
                @available(*, deprecated, message: "Models should be created by using `Database.create(id:)`")
                public required init(database: Database, id: InstanceKey) {
                    self.database = database
                    self.id = id
                }
            
                /**
                 The publisher to notify the object that the underlying data has changed.
                 */
                public let objectWillChange = ObservableObjectPublisher()
            
                /**
                 Create a new instance of the model.
                 - Parameter database: The database in which the instance is created.
                 - Parameter id: The unique id of the instance
                 */
                public static func create(in database: Database, id: InstanceKey, some: Int = 1) -> Self {
                    func areNotEqual<T>(_ a: T, _ b: T) -> Bool {
                        false
                    }
                    func areNotEqual<T: Equatable>(_ a: T, _ b: T) -> Bool {
                        a != b
                    }
                    let instance: Self = database.create(id: id)
                    if areNotEqual(some, 1) {
                        instance.some = some
                    }
                    return instance
                }
            
                /**
                 All properties tracked by the model.
                 */
                public enum PropertyId: PropertyKey, CaseIterable {
                    case some = 1
                }
            
                /**
                 Delete the instance and reset overwrite all properties with default values
                 */
                public func deleteAndClearProperties() {
                    some = 1
                    self.delete()
                }
            }

            extension PublicModel: ModelProtocol {
            }
            
            extension PublicModel: ObservableObject {
            }
            """,
            macros: testMacros
        )
    #else
    throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
    }

    func testGeneratePrivateModel() throws {
    #if canImport(StateModelMacros)
        assertMacroExpansion(
            """
            @Model(id: 1)
            private final class PrivateModel {

                @Property(id: 1)
                var some: Int = 1
            }
            """,
            expandedSource:
            """
            private final class PrivateModel {

                @Property(id: 1)
                var some: Int = 1

                /**
                 The unique id of this model in the database.
                 */
                fileprivate static let modelId: ModelKey = 1

                /// The reference to the database to which this object is linked
                fileprivate unowned let database: Database

                /// The unique id of the instance
                fileprivate let id: InstanceKey

                /**
                 Create a model.
                 - Parameter database: The reference to the model database to read and write property values
                 - Parameter id: The unique id of the instance
                 - Note: This initializer should never be used directly. Create object through the database functions
                 */
                @available(*, deprecated, message: "Models should be created by using `Database.create(id:)`")
                fileprivate required init(database: Database, id: InstanceKey) {
                    self.database = database
                    self.id = id
                }
            
                /**
                 The publisher to notify the object that the underlying data has changed.
                 */
                fileprivate let objectWillChange = ObservableObjectPublisher()
            
                /**
                 Create a new instance of the model.
                 - Parameter database: The database in which the instance is created.
                 - Parameter id: The unique id of the instance
                 */
                fileprivate static func create(in database: Database, id: InstanceKey, some: Int = 1) -> Self {
                    func areNotEqual<T>(_ a: T, _ b: T) -> Bool {
                        false
                    }
                    func areNotEqual<T: Equatable>(_ a: T, _ b: T) -> Bool {
                        a != b
                    }
                    let instance: Self = database.create(id: id)
                    if areNotEqual(some, 1) {
                        instance.some = some
                    }
                    return instance
                }
            
                /**
                 All properties tracked by the model.
                 */
                fileprivate enum PropertyId: PropertyKey, CaseIterable {
                    case some = 1
                }
            
                /**
                 Delete the instance and reset overwrite all properties with default values
                 */
                fileprivate func deleteAndClearProperties() {
                    some = 1
                    self.delete()
                }
            }

            extension PrivateModel: ModelProtocol {
            }
            
            extension PrivateModel: ObservableObject {
            }
            """,
            macros: testMacros
        )
    #else
    throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
    }
}
