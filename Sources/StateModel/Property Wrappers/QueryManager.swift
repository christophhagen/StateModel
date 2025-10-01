import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class QueryManager<Result: ModelProtocol>: QueryObserver {

    var results: [Result] = []

    /// The filter to apply to the instances
    let filter: ((Result) -> Bool)?

    let isOrderedBefore: ((Result, Result) -> Bool)?

    weak var database: ObservableDatabase?

    init(database: ObservableDatabase?, filter: ((Result) -> Bool)? = nil, order: ((Result, Result) -> Bool)? = nil) {
        self.database = database
        self.filter = filter
        self.isOrderedBefore = order
    }

    func update(database: ObservableDatabase) {
        guard self.database == nil else {
            return
        }
        self.database = database
        let results: [Result] = database.queryAll(observer: self, where: { _ in true })
        if let filter {
            if let isOrderedBefore {
                self.results = results.filter(filter).sorted(by: isOrderedBefore)
            } else {
                self.results = results.filter(filter)
            }
        } else if let isOrderedBefore {
            self.results = results.sorted(by: isOrderedBefore)
        } else {
            self.results = results
        }
    }

    override func didUpdate(instance id: InstanceKey) {
        guard let index = results.firstIndex(where: { $0.id == id }) else {
            handleNewInstance(id: id)
            return
        }
        let instance = results[index]
        if let filter, !filter(instance) {
            results.remove(at: index)
        }
        if let isOrderedBefore {
            let newIndex = results.firstIndex { !isOrderedBefore($0, instance) } ?? results.endIndex
            if newIndex != index {
                results.move(fromOffsets: IndexSet(integer: index), toOffset: newIndex)
            }
        }
        self.objectWillChange.send()
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
        if let filter, !filter(instance) {
            return
        }
        // Insert new instance
        if let isOrderedBefore {
            let insertIndex = results.firstIndex { !isOrderedBefore($0, instance) } ?? results.endIndex
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
