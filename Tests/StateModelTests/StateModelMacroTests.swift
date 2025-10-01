import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import StateModel

#if canImport(StateModelMacros)
import StateModelMacros

nonisolated(unsafe) private let testMacros: [String: Macro.Type] = [
    "Model" : ModelMacro.self,
    "ObservableModel": ObservableModelMacro.self
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
                public required init(database: Database, id: InstanceKey) {
                    self.database = database
                    self.id = id
                }
            }

            extension GenericModel: ModelProtocol {
            }
            """,
            macros: testMacros
        )
    #else
    throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
    }

    func testObservableModelMacroExpansionWithConcreteDatabase() throws {
        #if canImport(StateModelMacros)
        assertMacroExpansion(
            """
            @ObservableModel(id: 1)
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
                public required init(database: Database, id: InstanceKey) {
                    self.database = database
                    self.id = id
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
