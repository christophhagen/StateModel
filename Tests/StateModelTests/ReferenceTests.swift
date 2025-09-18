import Testing
import StateModel

@Suite("References")
struct ReferenceTests {

    @Test("Set and get reference")
    func testReferenceProperty() throws {
        let database = TestDatabase()

        let instanceA: TestModel = database.create(id: 123)
        instanceA.a = 123
        instanceA.b = 234
        #expect(instanceA.ref == nil)

        let nested: NestedModel = database.create(id: 123)
        instanceA.ref = nested
        #expect(instanceA.ref == nested)

        instanceA.ref = nil
        #expect(instanceA.ref == nil)
    }


    @Test("Delete referenced models")
    func testReferenceDeletion() {
        let database = TestDatabase()

        let model = database.create(id: 1, of: TestModel.self)
        let nested = database.create(id: 123, of: NestedModel.self)
        #expect(model.ref == nil)
        model.ref = nested
        nested.delete()
        #expect(nested.status == .deleted)
        #expect(model.ref != nil)
        #expect(model.ref!.status == .deleted)
    }

}
