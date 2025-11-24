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

        // No more bounds checks needed here
        let target = newIndex > index ? newIndex + 1 : newIndex
        moveUnchecked(at: index, to: target)
    }

    mutating func moveElement(at offset: Int, to target: Int) {
        // Validate indices
        guard offset >= 0, offset < count, target >= 0, target <= count, offset != target else { return }
        moveUnchecked(at: offset, to: target)
    }

    private mutating func moveUnchecked(at offset: Int, to target: Int) {
        // If moving forward in the array, removing first shifts subsequent indices left by 1,
        // so we insert at `target - 1`. If moving backward, indices before `offset` are unaffected.
        if offset < target {
            let element = self.remove(at: offset)
            self.insert(element, at: target - 1)
        } else {
            let element = self.remove(at: offset)
            self.insert(element, at: target)
        }
    }
}
