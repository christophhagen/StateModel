import Foundation
import Testing
import StateModel

private typealias TestHistoryDatabase = InMemoryHistoryDatabase

@Suite("Editing context")
struct EditingContextTests {

    @Test("Modify and commit")
    func testEditPropertyInContext() async throws {
        let database = TestHistoryDatabase()

        let aInDatabase: TestModel = database.create(id: 123)
        aInDatabase.a = 42
        aInDatabase.b = 1337

        let context = database.createEditingContext()
        let aInContext: TestModel! = context.active(id: 123)
        #expect(aInContext != nil)
        #expect(aInContext.a == 42)
        #expect(aInContext.b == 1337)

        // Modify in context, check if still the same in database
        aInContext.a = 43
        #expect(aInContext.a == 43)

        #expect(aInDatabase.a == 42)

        // Commit, check again
        context.commitChanges()

        #expect(aInContext.a == 43)
        #expect(aInDatabase.a == 43)
    }

    @Test("Modify outside of context")
    func testEditPropertyOutsideOfContext() async throws {
        let database = TestHistoryDatabase()

        let aInDatabase: TestModel = database.create(id: 123)
        aInDatabase.a = 42
        aInDatabase.b = 1337

        let context = database.createEditingContext()
        let aInContext: TestModel! = context.active(id: 123)
        #expect(aInContext != nil)
        #expect(aInContext.a == 42)
        #expect(aInContext.b == 1337)

        try await sleep(ms: 50)

        aInDatabase.a = 43
        aInDatabase.b = 1338

        #expect(aInDatabase.a == 43)
        #expect(aInDatabase.b == 1338)

        // Check that context is updated
        #expect(aInContext.a == 43)
        #expect(aInContext.b == 1338)
    }

    @Test("Modify outside of snapshot context")
    func testEditPropertyOutsideOfCurrentContext() async throws {
        let database = TestHistoryDatabase()

        let aInDatabase: TestModel = database.create(id: 123)
        aInDatabase.a = 42
        aInDatabase.b = 1337

        let context = database.createEditingContextWithCurrentState()
        let aInContext: TestModel! = context.active(id: 123)
        #expect(aInContext != nil)
        #expect(aInContext.a == 42)
        #expect(aInContext.b == 1337)

        try await sleep(ms: 50)

        aInDatabase.a = 43
        aInDatabase.b = 1338

        #expect(aInDatabase.a == 43)
        #expect(aInDatabase.b == 1338)

        // Check that context is not affected
        #expect(aInContext.a == 42)
        #expect(aInContext.b == 1337)
    }

    @Test("Discard changes")
    func testContextDiscardChanges() async throws {
        let database = TestHistoryDatabase()

        let aInDatabase: TestModel = database.create(id: 123)
        aInDatabase.a = 42
        aInDatabase.b = 1337

        let context = database.createEditingContext()
        let aInContext: TestModel! = context.active(id: 123)
        #expect(aInContext != nil)

        aInContext.a = 43
        #expect(aInContext.a == 43)

        context.discardChanges()

        #expect(aInContext.a == 42)
        #expect(aInDatabase.a == 42)
        #expect(aInDatabase.b == 1337)
    }

    @Test("Create new instance")
    func testContextCreateNewInstance() async throws {
        let database = TestHistoryDatabase()

        do {
            let beforeInsert: TestModel? = database.get(id: 123)
            #expect(beforeInsert == nil)
        }

        let context = database.createEditingContext()
        do {
            let newModel: TestModel = context.getOrCreate(id: 123)
            #expect(newModel.a == 0)
        }

        do {
            let beforeCommit: TestModel? = database.get(id: 123)
            #expect(beforeCommit == nil)
        }

        context.commitChanges()

        do {
            let afterCommit: TestModel! = database.get(id: 123)
            #expect(afterCommit != nil)
            #expect(afterCommit.status == .created)
        }
    }

    @Test("Get new instances in context")
    func testContextGetNewInstancesInContext() async throws {
        let database = TestHistoryDatabase()

        do {
            let oldModel: TestModel = database.create(id: 100)
            oldModel.a = 1
        }

        let context = database.createEditingContext()

        do {
            let newModel: TestModel = context.getOrCreate(id: 123)
            newModel.a = 42
        }

        do {
            let allBeforeCommit: [TestModel] = database.all()
            #expect(allBeforeCommit.count == 1)
            #expect(allBeforeCommit[0].a == 1)
        }

        do {
            let allInContext: [TestModel] = context.all()
            #expect(allInContext.count == 2)
            let newModel = allInContext.first { $0.id == 123 }
            #expect(newModel != nil)
            #expect(newModel!.a == 42)
        }

        context.commitChanges()

        do {
            let allAfterCommit: [TestModel] = database.all()
            #expect(allAfterCommit.count == 2)
            let newModel = allAfterCommit.first { $0.id == 123 }
            #expect(newModel != nil)
            #expect(newModel!.a == 42)
        }
    }
}
