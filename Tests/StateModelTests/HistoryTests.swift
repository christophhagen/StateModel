import Foundation
import Testing
import StateModel

private typealias TestHistoryDatabase = InMemoryHistoryDatabase<ModelId, Int, Int>

@Suite("History View")
struct HistoryViewTests {

    @Test("View old value")
    func viewOldValue() async throws {
        let database = TestHistoryDatabase()

        let instanceA: TestModel = database.create(id: 123)

        let start = Date()
        instanceA.a = 123
        #expect(instanceA.a == 123)

        try await sleep(ms: 500)
        #expect(instanceA.a == 123)
        instanceA.a = 456
        #expect(instanceA.a == 456)

        let history = database.view(at: start.addingTimeInterval(0.250))

        let oldA: TestModel = history.getOrCreate(id: 123)
        #expect(oldA.a == 123)

        #expect(instanceA.a == 456)
    }

    @Test("Write in history view")
    func writeInHistoryView() async throws {
        let database = TestHistoryDatabase()

        let start = Date()
        do {
            let instanceA: TestModel = database.create(id: 123)
            instanceA.a = 42
            #expect(instanceA.a == 42)
        }

        try await sleep(ms: 50)

        let history = database.view(at: start.addingTimeInterval(0.025))
        do {
            let instanceA: TestModel! = history.active(id: 123)
            #expect(instanceA != nil)
            #expect(instanceA.a == 42)

            instanceA.a = 1337
            #expect(instanceA.a == 42) // Expected to be unchanged
        }

        // Check that it's also unchanged in the original database
        do {
            let instanceA: TestModel = database.create(id: 123)
            #expect(instanceA.a == 42)
        }
    }

    @Test("Move history view")
    func moveHistoryView() async throws {

        let database = TestHistoryDatabase()

        let start = Date()
        let instanceA: TestModel = database.create(id: 123)
        instanceA.a = 42
        #expect(instanceA.a == 42)

        try await sleep(ms: 50)

        instanceA.a = 43

        let history = database.view(at: start.addingTimeInterval(0.025))
        do {
            let instanceA: TestModel! = history.active(id: 123)
            #expect(instanceA != nil)
            #expect(instanceA.a == 42)
        }

        history.moveView(to: Date())

        do {
            let instanceA: TestModel! = history.active(id: 123)
            #expect(instanceA != nil)
            #expect(instanceA.a == 43)
        }
    }
}
