import Testing
import StateModel

@Suite("Models")
struct ModelTests {
    /**
     Test if it's possible to query all models from a database, and if deleted instances are skipped
     */
    @Test("Get all instances")
    func testGetAllInstances() {
        let database = TestDatabase()

        var all = database.all(of: TestModel.self)
        #expect(all.isEmpty)

        let model1: TestModel = database.create(id: 1)
        let model2: TestModel = database.create(id: 2)
        let model3: TestModel = database.create(id: 3)
        let model4: TestModel = database.create(id: 4)

        all = database.all()
        #expect(all.count == 4)
        #expect(all.contains(model1))
        #expect(all.contains(model2))
        #expect(all.contains(model3))
        #expect(all.contains(model4))

        model2.delete()

        all = database.all()
        #expect(all.count == 3)
        #expect(all.contains(model1))
        #expect(!all.contains(model2))
        #expect(all.contains(model3))
        #expect(all.contains(model4))

        let nested1 = database.create(id: 1, of: NestedModel.self)

        all = database.all()
        #expect(all.count == 3)

        let allNested = database.all(of: NestedModel.self)
        #expect(allNested.count == 1)
        #expect(allNested.contains(nested1))
    }

    @Test("Filter instances")
    func testFilterModels() {
        let database = TestDatabase()

        let model1: TestModel = database.create(id: 1)
        let model2: TestModel = database.create(id: 2)
        let model3: TestModel = database.create(id: 3)

        model1.a = 3
        model2.a = 15
        model3.a = 36

        let below = database.all(TestModel.self) { $0.a > 10 }
        #expect(below.count == 2)
        #expect(below.contains(model2))
        #expect(below.contains(model3))
    }

    @Test("Delete instances")
    func testDeleteInstances() {
        let database = TestDatabase()

        let model = database.create(id: 1, of: TestModel.self)
        #expect(model.status == .created)
        model.a = 123
        #expect(model.a == 123)

        model.delete()
        #expect(database.all(of: TestModel.self).isEmpty)
        #expect(model.status == .deleted)
        #expect(model.a == 123)

        let other = database.get(id: model.id, of: TestModel.self)
        #expect(other != nil)
        #expect(other!.status == .deleted)
        #expect(other == model)

        model.insert()
        #expect(model.status == .created)
        #expect(model.a == 123)
    }

    @Test("Modify nested models")
    func testModelModification() {
        let database = TestDatabase()

        let model = database.create(id: 1, of: TestModel.self)
        let nested = database.create(id: 123, of: NestedModel.self)
        #expect(model.ref == nil)
        model.ref = nested
        #expect(model.ref != nil)
        #expect(model.ref!.id == 123)
        model.ref!.some = 5
        #expect(nested.some == 5)
        model.ref = nil
        #expect(model.ref == nil)
        #expect(nested.some == 5)
    }
}
