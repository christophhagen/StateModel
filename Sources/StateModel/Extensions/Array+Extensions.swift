import Foundation

extension Array {
    /// Reposition the element at `index` to maintain sort order.
    /// Searches backward first, then forward, and performs a single move.
    mutating func resortElement(
        at index: Int,
        by areInIncreasingOrder: (Element, Element) -> Bool
    ) {
        guard !isEmpty, index >= 0, index < count else { return }

        let element = self[index]

        var newIndex = index

        // Search backward
        while newIndex > 0 && !areInIncreasingOrder(self[newIndex - 1], element) {
            newIndex -= 1
        }

        // If backward search didn't move it, search forward
        if newIndex == index {
            while newIndex < count - 1 && !areInIncreasingOrder(element, self[newIndex + 1]) {
                newIndex += 1
            }
        }

        guard newIndex != index else {
            return
        }

        self.move(fromOffsets: IndexSet(integer: index), toOffset: newIndex > index ? newIndex + 1 : newIndex)
    }
}
