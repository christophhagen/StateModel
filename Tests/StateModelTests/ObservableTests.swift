import Foundation
import Testing
@testable import StateModel
#if canImport(Combine)
import Combine
#else
import OpenCombine
#endif

private typealias ObservableTestDatabase = InMemoryDatabase

@Model(id: 1)
private final class ObservableTestModel {

    @Property(id: 1)
    var a: Int

    @Reference(id: 2)
    var item: ObservableNestedModel?

    @ReferenceList(id: 3)
    var items: [ObservableNestedModel]
}

@Model(id: 2)
private final class ObservableNestedModel {

    @Property(id: 1)
    var value: Int
}

@Suite("Observable")
struct ObservableTests {

    @Test("Trigger update on property change")
    func triggerUpdateOnPropertyChange() async throws {
        let baseDatabase = ObservableTestDatabase()
        let database = ObservableDatabase(wrapping: baseDatabase)

        let object: ObservableTestModel = database.create(id: 123)

        await observeChange(to: object) {
            object.a = 123
        }
    }

    @Test("Trigger update on existing instance")
    func triggerUpdateAfterGettingAllModels() async throws {
        let baseDatabase = ObservableTestDatabase()
        let database = ObservableDatabase(wrapping: baseDatabase)

        let object: ObservableTestModel = database.create(id: 123)
        object.a = 123

        let all: [ObservableTestModel] = database.all()
        #expect(all.count == 1)
        let otherReference = all.first!


        await observeChange(to: object) {
            otherReference.a = 124
            #expect(object.a == 124)
            #expect(otherReference.a == 124)
        }
    }

    @Test("Trigger an update manually")
    func manuallyTriggerUpdate() async throws {
        let baseDatabase = ObservableTestDatabase()
        let database = ObservableDatabase(wrapping: baseDatabase)

        let object: ObservableTestModel = database.create(id: 123)
        object.a = 42
        #expect(object.a == 42)

        await observeChange(to: object) {
            let path = Path(
                model: ObservableTestModel.modelId,
                instance: object.id,
                property: ObservableTestModel.PropertyId.a)
            baseDatabase.set(43, for: path)
            database.updateChangedObject(model: ObservableTestModel.modelId, instance: object.id)
        }
        #expect(object.a == 43)
    }

    @Test("Observe reference element")
    func observeReferenceElement() async throws {
        let baseDatabase = ObservableTestDatabase()
        let database = ObservableDatabase(wrapping: baseDatabase)

        let object: ObservableTestModel = database.create(id: 123)

        let nested: ObservableNestedModel = database.create(id: 234)
        nested.value = 42
        object.item = nested

        let referenced: ObservableNestedModel! = object.item
        #expect(referenced != nil)
        #expect(referenced.value == 42)

        await observeChange(to: referenced, "No update triggered for nested object") {
            nested.value = 43
        }
    }

    @Test("Observe reference list elements")
    func observeReferenceListElements() async throws {
        let baseDatabase = ObservableTestDatabase()
        let database = ObservableDatabase(wrapping: baseDatabase)

        let object: ObservableTestModel = database.create(id: 123)

        let nested: ObservableNestedModel = database.create(id: 234)
        nested.value = 42
        object.items.append(nested)

        #expect(object.items.count == 1)
        let referenced = object.items[0]
        #expect(referenced.value == 42)

        await observeChange(to: referenced, "No update triggered for nested object") {
            nested.value = 43
        }
    }

#if canImport(SwiftUI)
    @Test("Test query filtering")
    func testFilterOfQueryResults() async throws {
        let baseDatabase = ObservableTestDatabase()
        let database = ObservableDatabase(wrapping: baseDatabase)

        let values = [10, 30, 20, 0, 40]
        for value in values {
            let object = database.create(id: value + 100, of: ObservableTestModel.self)
            object.a = value
        }

        let descriptor = QueryDescriptor<ObservableTestModel>(filter: { $0.a < 15 || $0.a > 25 })
        let observer = QueryManager<ObservableTestModel>(database: database, descriptor: descriptor)
        observer.refreshResults()
        let filtered = observer.results
        #expect(filtered.count == 4)
        #expect(Set(filtered.map { $0.a }) == [0, 10, 30, 40])
    }

    @Test("Test query sorting")
    func testSortingOfQueryResults() async throws {
        let baseDatabase = ObservableTestDatabase()
        let database = ObservableDatabase(wrapping: baseDatabase)

        let values = [10, 30, 20, 0, 40]
        for value in values {
            let object = database.create(id: value + 100, of: ObservableTestModel.self)
            object.a = value
        }

        let descriptor = QueryDescriptor<ObservableTestModel>(sortBy: { $0.a })
        let observer = QueryManager<ObservableTestModel>(database: database, descriptor: descriptor)
        observer.refreshResults()
        let all = observer.results
        #expect(all.count == 5)
        #expect(all.map { $0.a } == [0, 10, 20, 30, 40])
    }

    @Test("Test query sorting and filtering")
    func testSortingAndFilteringOfQueryResults() async throws {
        let baseDatabase = ObservableTestDatabase()
        let database = ObservableDatabase(wrapping: baseDatabase)

        let values = [10, 30, 20, 0, 40]
        for value in values {
            let object = database.create(id: value + 100, of: ObservableTestModel.self)
            object.a = value
        }

        let descriptor = QueryDescriptor<ObservableTestModel>(filter: { $0.a > 5 && $0.a < 35 }, sortBy: { $0.a })
        let observer = QueryManager<ObservableTestModel>(database: database, descriptor: descriptor)
        observer.refreshResults()
        let all = observer.results
        #expect(all.count == 3)
        #expect(all.map { $0.a } == [10, 20, 30])
    }
#endif
}

public func observeChange<O: ObservableObject>(
    to object: O,
    _ message: String? = nil,
    trigger: () throws -> Void
) async rethrows {
    var cancellables: Set<AnyCancellable> = []
    let comment = message.map { Comment.init(stringLiteral: $0) }
    try await confirmation(comment) { confirm in
        // Subscribe before triggering
        object.objectWillChange
            .sink { _ in confirm() }
            .store(in: &cancellables)

        try trigger()
    }
}
