import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class QueryManager<Result: ModelProtocol>: QueryObserver {

    var results: [Result] = []

    private var descriptor: QueryDescriptor<Result>

    weak var database: ObservableDatabase?

    init(database: ObservableDatabase?, descriptor: QueryDescriptor<Result>) {
        self.database = database
        self.descriptor = descriptor
    }

    func update(descriptor: QueryDescriptor<Result>) {
        guard self.descriptor != descriptor else {
            return
        }
        self.descriptor = descriptor
        refreshResults()
    }

    func update(database: ObservableDatabase) {
        guard self.database == nil else {
            return
        }
        self.database = database
        refreshResults()
    }

    private func refreshResults() {
        guard let database else {
            self.results = []
            return
        }
        let results: [Result] = database.queryAll(observer: self, where: descriptor.isIncluded)
        if let areInIncreasingOrder = self.descriptor.areInIncreasingOrder {
            self.results = results.sorted(by: areInIncreasingOrder)
        } else {
            self.results = results
        }
    }

    override func didUpdate(instance id: InstanceKey) {
        guard let index = results.firstIndex(where: { $0.id == id }) else {
            handleNewInstance(id: id)
            return
        }
        defer { self.objectWillChange.send() }
        if let isIncluded = descriptor.isIncluded, !isIncluded(results[index]) {
            results.remove(at: index)
            return
        }
        guard let areInIncreasingOrder = descriptor.areInIncreasingOrder else {
            return
        }

        results.resortElement(at: index, by: areInIncreasingOrder)
    }

    private func handleNewInstance(id: InstanceKey) {
        guard let database else {
            return
        }
        guard let instance: Result = database.get(id: id) else {
            remove(instance: id)
            return
        }
        // Filter out instances
        if let isIncluded = descriptor.isIncluded, !isIncluded(instance) {
            return
        }
        // Insert new instance
        if let areInIncreasingOrder = descriptor.areInIncreasingOrder {
            let insertIndex = results.firstIndex { !areInIncreasingOrder($0, instance) } ?? results.endIndex
            results.insert(instance, at: insertIndex)
        } else {
            results.append(instance)
        }
        self.objectWillChange.send()
    }

    private func remove(instance id: InstanceKey) {
        if let index = results.firstIndex(where: {$0.id == id }) {
            results.remove(at: index)
        }
    }
}
