import Foundation
import Testing
import StateModel
import Combine

private typealias ObservableTestDatabase = InMemoryDatabase

@ObservableModel(id: 1)
private final class ObservableTestModel {

    @Property(id: 1)
    var a: Int

    @Reference(id: 2)
    var item: ObservableNestedModel?

    @ReferenceList(id: 3)
    var items: [ObservableNestedModel]
}

@ObservableModel(id: 2)
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
