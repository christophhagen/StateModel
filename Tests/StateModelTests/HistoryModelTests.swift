import Foundation
import Testing
@testable import StateModel

private typealias TestHistoryDatabase = InMemoryHistoryDatabase<ModelId, Int, Int>

@Test("History Property get old value")
func testHistoryPropertyOldValue() async throws {
    let database = TestHistoryDatabase()

    let instanceA: TestModel = database.create(id: 123)

    let start = Date()
    instanceA.a = 123
    #expect(instanceA.a == 123)

    try await Task.sleep(nanoseconds: 1_000_000_000)
    #expect(instanceA.a == 123)
    instanceA.a = 456
    #expect(instanceA.a == 456)

    let history = database.view(at: start.addingTimeInterval(0.5))

    let oldA: TestModel = history.getOrCreate(id: 123)
    #expect(oldA.a == 123)

    #expect(instanceA.a == 456)
}
