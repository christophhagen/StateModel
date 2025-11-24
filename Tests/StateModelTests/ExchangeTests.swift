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
    case 1: return TestModel.self
    case 123: return SomeUpdatable.self
    default: return nil
    }
}

@Suite("Data exchange")
struct ExchangeTests {

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

        let localClient = UpdateConsumer(
            database: localDB,
            encoder: JSONEncoder(),
            decoder: JSONDecoder(),
            modelMap: mapModel)


        let command = localModel.addValuesCommand(lhs: 3, rhs: 4)
        let commandRequest = try localClient.encode(command: command)

        #expect(remoteModel.value == 21)
        #expect(localModel.value == 42)

        let remoteClient = RequestProcessor(
            database: remoteDB,
            encoder: JSONEncoder(),
            decoder: JSONDecoder(),
            modelMap: mapModel)

        let commandResponse = try remoteClient.process(command: commandRequest)
        #expect(remoteModel.value == 7)
        #expect(localModel.value == 42)

        try localClient.decode(commandResponse: commandResponse)
    }

    @Test("Instance update")
    func testUpdateInjection() throws {
        let remoteDB = TestDatabase()
        let remoteModel: SomeUpdatable = remoteDB.create(id: 123)
        remoteModel.value = 42
        #expect(remoteModel.value == 42)

        let localDB = TestDatabase()
        let localModel: SomeUpdatable = localDB.create(id: 123)
        localModel.value = 21
        #expect(localModel.value == 21)
        #expect(remoteModel.value == 42)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let timestamp = Date()

        remoteModel.value = 666

        let remoteClient = UnencodedRequestProcessor(
            database: remoteDB,
            encoder: encoder,
            decoder: decoder,
            modelMap: mapModel)
        let update = remoteClient.updates(for: localModel.id, of: SomeUpdatable.modelId, after: timestamp)

        #expect(update.instance == localModel.id)
        #expect(update.model == SomeUpdatable.modelId)
        #expect(update.properties.count == 2)

        let localClient = UnencodedUpdateConsumer(
            database: localDB,
            decoder: decoder,
            encoder: encoder,
            modelMap: mapModel)

        #expect(localModel.value == 21)
        try localClient.apply(instanceUpdate: update)
        #expect(localModel.value == 666)
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

        remoteModel.delete()
        _ = remoteDB.create(id: 124, of: SomeUpdatable.self)

        let localClient = UpdateConsumer(
            database: localDB,
            encoder: encoder,
            decoder: decoder,
            modelMap: mapModel)

        let request = try localClient.instanceStatusRequest(for: SomeUpdatable.self, after: time)

        let remoteClient = RequestProcessor(
            database: remoteDB,
            encoder: encoder,
            decoder: decoder,
            modelMap: mapModel)

        let update = try remoteClient.process(instanceStatusRequest: request)

        #expect(localModel.status == .created)
        #expect(localDB.get(id: 124, of: SomeUpdatable.self) == nil)

        try localClient.apply(instanceUpdates: update)

        #expect(localModel.status == .deleted)
        let newInstance = localDB.get(id: 124, of: SomeUpdatable.self)
        #expect(newInstance != nil)
        guard let newInstance else { return }
        #expect(newInstance.status == .created)
    }

    @Test("Generic apply function")
    func testGenericApplyFunction() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let localDB = TestDatabase()
        let localModel: SomeUpdatable = localDB.create(id: 123)

        let remoteDB = TestDatabase()
        let remoteModel: SomeUpdatable = remoteDB.create(id: 123)

        let time = Date()

        remoteModel.delete()
        _ = remoteDB.create(id: 124, of: SomeUpdatable.self)

        let localClient = UpdateConsumer(
            database: localDB,
            encoder: encoder,
            decoder: decoder,
            modelMap: mapModel)

        let request = try localClient.instanceStatusRequest(for: SomeUpdatable.self, after: time)

        let remoteClient = RequestProcessor(
            database: remoteDB,
            encoder: encoder,
            decoder: decoder,
            modelMap: mapModel)

        let update = try remoteClient.process(instanceStatusRequest: request)

        #expect(localModel.status == .created)
        #expect(localDB.get(id: 124, of: SomeUpdatable.self) == nil)

        try localClient.apply(data: update)

        #expect(localModel.status == .deleted)
        let newInstance = localDB.get(id: 124, of: SomeUpdatable.self)
        #expect(newInstance != nil)
        guard let newInstance else { return }
        #expect(newInstance.status == .created)
    }

    @Test("Model updates")
    func testModelUpdates() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let localDB = TestDatabase()
        let remoteDB = TestDatabase()
        let localClient = UpdateConsumer(
            database: localDB,
            encoder: encoder,
            decoder: decoder,
            modelMap: mapModel)
        let remoteClient = RequestProcessor(
            database: remoteDB,
            encoder: encoder,
            decoder: decoder,
            modelMap: mapModel)

        // Make updates on the server
        do {
            let instance1: TestModel = remoteDB.create(id: 1)
            instance1.a = 123
            instance1.b = 234
            instance1.d = true

            let instance2: TestModel = remoteDB.create(id: 123)
            instance2.a = 345
            instance2.b = 456
            instance2.d = true

            let instance3: TestModel = remoteDB.create(id: 234)
            instance3.a = 567
            instance3.b = 678
            instance3.delete()
        }

        // Get first batch of updates
        var nextInstance: InstanceKey?
        do {
            let request = try localClient.modelUpdateRequest(for: TestModel.self, after: nil, limit: 5)
            let update = try remoteClient.process(modelUpdateRequest: request)
            nextInstance = try localClient.apply(modelUpdates: update)
        }
        #expect(nextInstance == 123)

        // Check that only some instances are updated
        do {
            let instance1 = localDB.get(id: 1, of: TestModel.self)
            #expect(instance1 != nil)
            #expect(instance1?.status == .created)
            #expect(instance1?.a == 123)
            #expect(instance1?.b == 234)
            #expect(instance1?.d == true)
            #expect(localDB.get(id: 123, of: TestModel.self) == nil)
            #expect(localDB.get(id: 234, of: TestModel.self) == nil)
        }

        // Get second batch of updates
        do {
            let request = try localClient.modelUpdateRequest(for: TestModel.self, after: nil, limit: 5, startingAt: nextInstance)
            let update = try remoteClient.process(modelUpdateRequest: request)
            nextInstance = try localClient.apply(modelUpdates: update)
        }

        // Check that more instances are updated
        do {
            let instance1 = localDB.get(id: 1, of: TestModel.self)
            #expect(instance1 != nil)
            #expect(instance1?.status == .created)
            #expect(instance1?.a == 123)
            #expect(instance1?.b == 234)
            #expect(instance1?.d == true)

            let instance2 = localDB.get(id: 123, of: TestModel.self)
            #expect(instance2 != nil)
            #expect(instance2?.status == .created)
            #expect(instance2?.a == 345)
            #expect(instance2?.b == 456)
            #expect(instance2?.d == true)

            #expect(localDB.get(id: 234, of: TestModel.self) == nil)
        }

        // Get final batch
        do {
            let request = try localClient.modelUpdateRequest(for: TestModel.self, after: nil, limit: 5, startingAt: nextInstance)
            let update = try remoteClient.process(modelUpdateRequest: request)
            nextInstance = try localClient.apply(modelUpdates: update)
        }

        // Check that all instances are updated
        do {
            let instance1 = localDB.get(id: 1, of: TestModel.self)
            #expect(instance1 != nil)
            #expect(instance1?.status == .created)
            #expect(instance1?.a == 123)
            #expect(instance1?.b == 234)
            #expect(instance1?.d == true)

            let instance2 = localDB.get(id: 123, of: TestModel.self)
            #expect(instance2 != nil)
            #expect(instance2?.status == .created)
            #expect(instance2?.a == 345)
            #expect(instance2?.b == 456)
            #expect(instance2?.d == true)

            let instance3 = localDB.get(id: 234, of: TestModel.self)
            #expect(instance3 != nil)
            #expect(instance3?.status == .deleted)
            #expect(instance3?.a == 567)
            #expect(instance3?.b == 678)
            #expect(instance3?.d == false)
        }
    }
}
