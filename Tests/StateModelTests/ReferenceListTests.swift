import Testing
import StateModel

private final class SetModel: TestBaseModel {

    static let modelId = ModelId.testModel.rawValue

    @ReferenceList(id: 1)
    var list: Set<NestedModel>
}


@Suite("Reference Lists")
struct ReferenceListTests {

    @Test("Set and get list property")
    func testListProperty() {
        let database = TestDatabase()

        // Create a new model, defaults to an empty list
        let instanceA: TestModel = database.create(id: 123)
        #expect(instanceA.list.isEmpty)

        // Create an element for the list
        let other: NestedModel = database.create(id: 234)
        #expect(!instanceA.list.contains(other))
        other.some = 42
        #expect(other.some == 42)

        // Insert it into the list
        instanceA.list.append(other)
        #expect(instanceA.list.contains(other))

        instanceA.list[0].some = 43
        #expect(other.some == 43)

        // Remove it from the list
        instanceA.list.remove(at: 0)
        #expect(instanceA.list.isEmpty)

        // Check that content still exists
        #expect(other.status == .created)
        #expect(other.some == 43)
    }

    @Test("Deleted elements in list")
    func testDeletedElementsInList() {
        let database = TestDatabase()
        
        let other: NestedModel = database.create(id: 234)
        other.some = 42

        do {
            let instanceA: TestModel = database.create(id: 123)
            instanceA.list.append(other)
        }

        #expect(other.status == .created)
        other.delete()
        #expect(other.status == .deleted)

        do {
            let instanceA: TestModel! = database.active(id: 123)
            #expect(instanceA != nil)
            let list = instanceA.list
            #expect(list.count == 1)
            let nested = list[0]
            #expect(nested.status == .deleted)
        }
    }


    @Test("Delete referenced list items")
    func testDeletedListItems() {
        let database = TestDatabase()

        let model = database.create(id: 1, of: TestModel.self)
        let nested = database.create(id: 123, of: NestedModel.self)
        let nested2 = database.create(id: 234, of: NestedModel.self)

        model.list.append(nested)
        #expect(model.list.count == 1)
        model.list.append(nested2)
        #expect(model.list.count == 2)

        nested2.delete()
        #expect(nested2.status == .deleted)
        #expect(model.list.count == 2)
        #expect(model.list[0].status == .created)
        #expect(model.list[1].status == .deleted)
    }

    @Test("Set of elements")
    func testSetOfElements() {

        let database = TestDatabase()

        let instanceA: SetModel = database.create(id: 123)

        let element1: NestedModel = database.create(id: 1)
        let element2: NestedModel = database.create(id: 2)
        let element3: NestedModel = database.create(id: 3)

        #expect(instanceA.list.isEmpty)
        instanceA.list = [element1, element2, element3]
        #expect(instanceA.list.count == 3)
        #expect(instanceA.list == Set([element1, element2, element3]))
    }
}
