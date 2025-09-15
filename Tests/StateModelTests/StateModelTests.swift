import Testing
@testable import StateModel

@Test("Property get/set")
func testProperty() async throws {
    let database = TestDatabase()

    let instanceA: TestModel = database.create(id: 123)
    #expect(instanceA.a == 0)
    #expect(instanceA.b == -1)

    let instanceB: TestModel = database.create(id: 234)
    #expect(instanceB.a == 0)
    #expect(instanceB.b == -1)

    instanceA.a = 12
    instanceA.b = 56
    instanceB.a = 34
    instanceB.b = 67

    #expect(instanceA.a == 12)
    #expect(instanceA.b == 56)
    #expect(instanceB.a == 34)
    #expect(instanceB.b == 67)
}

@Test("Model reference")
func testReferenceProperty() throws {
    let database = TestDatabase()

    let instanceA: TestModel = database.create(id: 123)
    instanceA.a = 123
    instanceA.b = 234
    #expect(instanceA.ref == nil)

    let nested: NestedModel = database.create(id: 123)
    instanceA.ref = nested
    #expect(instanceA.ref == nested)
}

@Test("Model reference list")
func testListProperty() {
    let database = TestDatabase()

    let instanceA: TestModel = database.create(id: 123)
    #expect(instanceA.list.isEmpty)

    let other: NestedModel = database.create(id: 234)
    #expect(!instanceA.list.contains(other))
    other.some = 42
    #expect(other.some == 42)

    instanceA.list.append(other)
    #expect(instanceA.list.contains(other))


    instanceA.list[0].some = 43
    #expect(other.some == 43)
}

@Test("Transfer history")
func testTransferHistory() {
    let database1 = TestDatabase()

    let model1: TestModel = database1.create(id: 123)
    let nested1: NestedModel = database1.create(id: 234)
    model1.a = 123
    model1.b = 234
    model1.ref = nested1
    model1.list.append(nested1)
    nested1.some = 42

    let history = database1.getEncodedHistory()

    let database2 = TestDatabase()
    let inserted = database2.insert(records: history)
    #expect(inserted)

    let model2: TestModel! = database2.get(id: 123)
    #expect(model2 != nil)
    #expect(model2.a == 123)
    #expect(model2.b == 234)
    let nested2: NestedModel! = model2.ref
    #expect(nested2 != nil)
    #expect(model2.list.count == 1)
    #expect(model2.list[0] == nested2)
    #expect(nested2 == nested1)
    #expect(nested2.some == 42)
}

/**
 Test if it's possible to query all models from a database, and if deleted instances are skipped
 */
@Test("All models")
func testGetAllModels() {
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

@Test("Filter models")
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

@Test("Delete models")
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

@Test("Modify properties")
func testPropertyModification() {
    let database = TestDatabase()

    let model = database.create(id: 1, of: TestModel.self)

    model.a = 2
    #expect(model.a == 2)
    model.a += 3
    #expect(model.a == 5)

    let model2 = database.create(id: 2, of: TestModel.self)
    #expect(model2.a == 0)
    model2.a = model.a
    #expect(model2.a == 5)
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
