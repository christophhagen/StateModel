import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import StateModel
import Testing

#if canImport(StateModelMacros)
import StateModelMacros

nonisolated(unsafe) private let testMacros: [String: Macro.Type] = [
    "Model" : ModelMacro.self
]
#endif

final class MacroExpansionTests: XCTestCase {

    func testGenerateModelMacro() throws {
    #if canImport(StateModelMacros)
        assertMacroExpansion(
            """
            @Model(id: 1)
            final class GenericModel {

                @Property(id: 1)
                var some: Int = 1 // Trailing
            
                @Reference(id: 2)
                var nested: NestedModel! /* Trailing */
            
                @ReferenceList(id: 3)
                var list: [NestedModel] // Trailing
            }
            """,
            expandedSource:
            """
            final class GenericModel {

                @Property(id: 1)
                var some: Int = 1 // Trailing
            
                @Reference(id: 2)
                var nested: NestedModel! /* Trailing */
            
                @ReferenceList(id: 3)
                var list: [NestedModel] // Trailing

                /**
                 The unique id of this model in the database.
                 */
                static let modelId: ModelKey = 1

                /// The reference to the database to which this object is linked
                unowned let database: Database

                /// The unique id of the instance
                let id: InstanceKey

                /**
                 Create a model.
                 - Parameter database: The reference to the model database to read and write property values
                 - Parameter id: The unique id of the instance
                 - Note: This initializer should never be used directly. Create object through the database functions
                 */
                @available(*, deprecated, message: "Models should be created by using `Database.create(id:)`")
                required init(database: Database, id: InstanceKey) {
                    self.database = database
                    self.id = id
                }
            
                /**
                 The publisher to notify the object that the underlying data has changed.
                 */
                let objectWillChange = ObservableObjectPublisher()
            
                /**
                 Create a new instance of the model.
                 - Parameter database: The database in which the instance is created.
                 - Parameter id: The unique id of the instance
                 */
                static func create(in database: Database, id: InstanceKey, some: Int = 1, nested: NestedModel, list: [NestedModel] = .init()) -> Self {
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
                    instance.nested = nested
                    if areNotEqual(list, .init()) {
                        instance.list = list
                    }
                    return instance
                }
            
                /**
                 All properties tracked by the model.
                 */
                enum PropertyId: PropertyKey, CaseIterable {
                    case some = 1
                    case nested = 2
                    case list = 3
                }
            
                /**
                 Delete the instance and reset overwrite all properties with default values
                 */
                func deleteAndClearProperties() {
                    some = 1
                    nested = nil
                    list = .init()
                    self.delete()
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

@Suite("Macro Tests")
struct MacroTests {

    @Test("Create with generated function")
    func testCreateWithGeneratedFunction() {
        let database = TestDatabase()

        let nested = NestedModel.create(in: database, id: 57, some: 99)
        #expect(nested.status == .created)
        #expect(nested.id == 57)
        #expect(nested.some == 99)

        let object = TestModel.create(in: database, id: 123, a: 42, b: 43, ref: nested, list: [nested])
        #expect(object.status == .created)
        #expect(object.id == 123)
        #expect(object.a == 42)
        #expect(object.b == 43)
        #expect(object.ref != nil)
        #expect(object.ref!.id == nested.id)
        #expect(object.list.count == 1)
        #expect(object.list[0] == nested)
    }

    @Test("Skip default values")
    func testSkipDefaultValuesInCreate() {
        let database = TestDatabase()
        let object = TestModel.create(in: database, id: 123, a: 0, b: -1, ref: nil, list: [])

        let pathA = Path(model: TestModel.modelId, instance: object.id, property: TestModel.PropertyId.a.rawValue)
        let rawA: Int? = database.get(pathA)
        #expect(rawA == nil)

        let pathB = Path(model: TestModel.modelId, instance: object.id, property: TestModel.PropertyId.b.rawValue)
        let rawB: Int? = database.get(pathB)
        #expect(rawB == nil)

        let pathRef = Path(model: TestModel.modelId, instance: object.id, property: TestModel.PropertyId.ref.rawValue)
        let rawRef: Int? = database.get(pathRef)
        #expect(rawRef == nil)

        let pathList = Path(model: TestModel.modelId, instance: object.id, property: TestModel.PropertyId.list.rawValue)
        let rawList: [Int]? = database.get(pathList)
        #expect(rawList == nil)
    }
}
