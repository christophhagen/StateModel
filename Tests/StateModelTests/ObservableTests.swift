import Foundation
import Testing
import StateModel
import Combine

private typealias ObservableTestDatabase = InMemoryDatabase<Int, Int, Int>

private final class ObservableTestModel: ObservableModel<Int, Int, Int> {

    static let modelId = 1

    @Property(id: 1)
    var a: Int
}

@Suite("Observable")
struct ObservableTests {

    @Test("Trigger update on property change")
    func triggerUpdateOnPropertyChange() async throws {
        let baseDatabase = ObservableTestDatabase()
        let database = ObservableDatabase(wrapping: baseDatabase)

        let object: ObservableTestModel = database.create(id: 123)

        var cancellables: Set<AnyCancellable> = []
        let notified = AsyncStream<Void> { continuation in
            object.objectWillChange
                .sink { _ in continuation.yield(()) }
                .store(in: &cancellables)
        }

        object.a = 123

        _ = try await #require(notified.first { _ in true })
    }

    @Test("Trigger update on existing instance")
    func triggerUpdateAfterGettingAllModels() async throws {
        let baseDatabase = ObservableTestDatabase()
        let database = ObservableDatabase(wrapping: baseDatabase)

        let object: ObservableTestModel = database.create(id: 123)
        object.a = 123

        var cancellables: Set<AnyCancellable> = []
        let notified = AsyncStream<Void> { continuation in
            object.objectWillChange
                .sink { _ in continuation.yield(()) }
                .store(in: &cancellables)
        }

        let all: [ObservableTestModel] = database.all()
        #expect(all.count == 1)
        let otherReference = all.first!


        otherReference.a = 124
        #expect(object.a == 124)
        #expect(otherReference.a == 124)

        _ = try await #require(notified.first { _ in true })
    }
}
