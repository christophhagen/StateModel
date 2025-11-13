import Foundation
import Testing
import StateModel

@Model(id: 123)
final class SomeUpdatable {

    @Property(id: 1)
    var value: Int

    @Command(id: 12)
    func addValues(lhs: Int, rhs: Int) {
        value = lhs + rhs
    }
}

private func mapModel(modelId: Int) -> (any ModelProtocol.Type)? {
    switch modelId {
    case 123: return SomeUpdatable.self
    default: return nil
    }
}

@Suite("Execution")
struct ExecutionTests {

    @Test("Command execution")
    func testCommandExecution() throws {

        let localDB = TestDatabase()
        let localModel: SomeUpdatable = localDB.create(id: 123)
        localModel.value = 42
        #expect(localModel.value == 42)

        let remoteDB = TestDatabase()
        let remoteModel: SomeUpdatable = remoteDB.create(id: 123)
        remoteModel.value = 21

        #expect(remoteModel.value == 21)
        #expect(localModel.value == 42)

        let command = localModel.addValuesCommand(lhs: 3, rhs: 4)
        let commandData = try command.encoded(using: JSONEncoder())

        #expect(remoteModel.value == 21)
        #expect(localModel.value == 42)

        let executor = StateClient(
            database: remoteDB,
            decoder: JSONDecoder(),
            encoder: JSONEncoder(),
            modelMap: mapModel)

        try executor.run(command: commandData)
        #expect(remoteModel.value == 7)
        #expect(localModel.value == 42)
    }

    @Test("Instance update")
    func testUpdateInjection() throws {
        let localDB = TestDatabase()
        let localModel: SomeUpdatable = localDB.create(id: 123)
        localModel.value = 42
        #expect(localModel.value == 42)

        let remoteDB = TestDatabase()
        let remoteModel: SomeUpdatable = remoteDB.create(id: 123)
        remoteModel.value = 21
        #expect(remoteModel.value == 21)
        #expect(localModel.value == 42)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let timestamp = Date()

        localModel.value = 666

        let localClient = StateClient(
            database: localDB,
            decoder: decoder,
            encoder: encoder,
            modelMap: mapModel)
        let update = try localClient.updates(for: localModel.id, of: SomeUpdatable.modelId, after: timestamp)

        let remoteClient = StateClient(
            database: remoteDB,
            decoder: decoder,
            encoder: encoder,
            modelMap: mapModel)

        #expect(remoteModel.value == 21)
        try remoteClient.apply(instanceUpdate: update)
        #expect(remoteModel.value == 666)
    }

    @Test("Updates to instances")
    func testInstances() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let localDB = TestDatabase()
        let localModel: SomeUpdatable = localDB.create(id: 123)

        let remoteDB = TestDatabase()
        let remoteModel: SomeUpdatable = remoteDB.create(id: 123)

        let time = Date()

        localModel.delete()
        _ = localDB.create(id: 124, of: SomeUpdatable.self)

        let localClient = StateClient(
            database: localDB,
            decoder: decoder,
            encoder: encoder,
            modelMap: mapModel)

        let update = try localClient.instanceStatusUpdates(for: SomeUpdatable.self, after: time)

        let remoteClient = StateClient(
            database: remoteDB,
            decoder: decoder,
            encoder: encoder,
            modelMap: mapModel)

        #expect(remoteModel.status == .created)
        #expect(remoteDB.get(id: 124, of: SomeUpdatable.self) == nil)

        try remoteClient.apply(instanceUpdates: update)

        #expect(remoteModel.status == .deleted)
        let newInstance = remoteDB.get(id: 124, of: SomeUpdatable.self)
        #expect(newInstance != nil)
        guard let newInstance else { return }
        #expect(newInstance.status == .created)
    }
}
