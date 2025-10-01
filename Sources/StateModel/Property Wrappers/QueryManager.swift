import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class QueryManager<Result: ModelProtocol>: QueryObserver {

    var results: [Result] = []

    weak var database: ObservableDatabase?

    init(database: ObservableDatabase?) {
        self.database = database
    }

    func update(database: ObservableDatabase) {
        guard self.database == nil else {
            return
        }
        self.database = database
        results = database.queryAll(observer: self, where: { _ in true })
    }

    override func didUpdate(instance: InstanceKey) {
        guard results.contains(where: { $0.id == instance }) else {
            handleNewInstance(id: instance)
            return
        }
        self.objectWillChange.send()
    }

    private func handleNewInstance(id: InstanceKey) {
        guard let database else {
            return
        }
        guard let instance: Result = database.get(id: id) else {
            return
        }
        results.append(instance)
        self.objectWillChange.send()
    }
}
