//
//  ArrayRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 04/01/2024.
//

import Foundation

extension Array where Element: Equatable {
    public static func - (left: [Element], right: [Element]) -> [Element] {
        var result = [Element]()
        for ele in left where !right.contains(ele) {
            result.append(ele)
        }
        return result
    }
    //
    //    public static func - (left: Array<Element>, right: Optional<Array<Element>>) -> Array<Element> {
    //        let right = right ?? []
    //        return left - right
    //    }
    //
}

extension Array where Element: Equatable {
    // Remove first collection element that is equal to the given `object`:
    public mutating func removeObject(_ object: Iterator.Element) {
        if let index = firstIndex(of: object) {
            remove(at: index)
        }
    }

    public func splitAndCombine(makeFirst: Element) -> [Element] {
        guard let i = firstIndex(of: makeFirst) else {
            debugPrint("couldn't split the array properly")
            return self
        }
        var first = Array(self[i..<count])
        let second = Array(self[0..<i])
        first.append(contentsOf: second)
        return first
    }

    public var uniqueElements: [Element] {
        return reduce(into: []) {
            uniqueElements, element in

            if !uniqueElements.contains(element) {
                uniqueElements.append(element)
            }
        }
    }

    public mutating func toggle(_ object: Element) {
        if contains(object) {
            removeObject(object)
            return
        }
        append(object)
    }
}

public extension Sequence {
    func chunked(into size: Int) -> [[Element]] {
        let array = Array(self)
        return stride(from: 0, to: array.count, by: size).map {
            Array(array[$0..<Swift.min($0 + size, array.count)])
        }
    }

    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        return sorted { a, b in
            a[keyPath: keyPath] < b[keyPath: keyPath]
        }
    }
}

public extension Sequence where Element: Hashable {
    var asSet: Set<Element> {
        return Set<Element>(self)
    }
}

public extension Array {
    func first() -> Element? {
        if isEmpty {
            return nil
        }
        return self[0]
    }

    func last() -> Element? {
        if isEmpty {
            return nil
        }
        let index = count - 1
        return self[index]
    }

    func head() -> Element? {
        return first()
    }

    func tail() -> [Element] {
        if isEmpty || count == 1 {
            return []
        }
        let range: CountableRange<Int> = 1..<count
        let slice = self[range]
        return Array(slice)
    }
}

public protocol OptionalArray {}

extension Array: OptionalArray {}

// inspired from https://stackoverflow.com/questions/25738817/removing-duplicate-elements-from-an-array-in-swift
public extension Sequence where Iterator.Element: Hashable {
    /// only unique elements, but doesn't respect order
    func uniqueItemsSet() -> Set<Iterator.Element> {
        return Set<Iterator.Element>(self)
    }

    func uniqueItemsArray() -> [Iterator.Element] {
        return Array(uniqueItemsSet())
    }

    /// only unique elements, but keep order
    func uniqueItemsArrayMaintainedOrder() -> [Iterator.Element] {
        return reduce([Iterator.Element]()) { $0.contains($1) ? $0 : $0 + [$1] }
    }
}

public extension Set {
    var asArray: [Element] {
        return Array(self)
    }
}
