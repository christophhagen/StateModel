import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import StateModel

#if canImport(StateModelMacros)
import StateModelMacros

nonisolated(unsafe) private let testMacros: [String: Macro.Type] = [
    "Model" : ModelMacro.self
]
#endif

final class StateModelMacroTests: XCTestCase {

    func testStateMacroWithDatabaseProtocol() throws {
    #if canImport(StateModelMacros)
        assertMacroExpansion(
            """
            @Model(id: 1)
            final class GenericModel {

                @Property(id: 1)
                var some: Int = 1
            }
            """,
            expandedSource:
            """
            final class GenericModel {

                @Property(id: 1)
                var some: Int = 1

                static let modelId: Int = 1

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
            
                public let objectWillChange = ObservableObjectPublisher()
            
                /**
                 Create a new instance of the model.
                 - Parameter database: The database in which the instance is created.
                 - Parameter id: The unique id of the instance
                */
                static func create(in database: Database, id: InstanceKey, some: Int) -> Self {
                    let instance: Self = database.create(id: id)
                    instance.some = some
                    return instance
                }
            }

            extension GenericModel: ModelProtocol {
            }
            
            extension GenericModel: ObservableObject {
            }
            """,
            macros: testMacros
        )
    #else
    throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
    }
}
