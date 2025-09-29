import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class QueryManager<Result: ModelProtocol>: QueryObserver<Result.InstanceKey> {

    var results: [Result] = []

    typealias Storage = ObservableDatabase<Result.ModelKey, Result.InstanceKey, Result.PropertyKey>

    weak var database: Storage?

    init(database: Storage?) {
        print("QueryManager.init")
        self.database = database
    }

    func update(database: Storage) {
        guard self.database == nil else {
            return
        }
        print("QueryManager: Initial fetch")
        self.database = database
        results = database.queryAll(observer: self, where: { _ in true })
    }

    override func didUpdate(instance: Result.InstanceKey) {
        guard results.contains(where: { $0.id == instance }) else {
            handleNewInstance(id: instance)
            return
        }
        print("QueryManager: Did change instance \(instance)")
        self.objectWillChange.send()
    }

    private func handleNewInstance(id: Result.InstanceKey) {
        guard let database else {
            print("QueryManager: No database to handle new instance \(id)")
            return
        }
        guard let instance: Result = database.get(id: id) else {
            print("QueryManager: No new instance \(id)")
            return
        }
        print("QueryManager: Added new instance \(id)")
        results.append(instance)
        self.objectWillChange.send()
    }
}
