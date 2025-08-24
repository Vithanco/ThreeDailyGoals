//
//  TestListHeaders.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 16/01/2025.
//

import Foundation
import Testing

@testable import Three_Daily_Goals

struct PartialList: Identifiable {
    var id: String {
        return header.id
    }

    var header: ListHeader
    var list: [TaskItem]

}

extension Array where Element == PartialList {

    var reduced: Int {
        return self.reduce(0) { (result, next) in
            return result + next.list.count
        }
    }
}

@MainActor
@Suite
struct TestListHeaders {

    @Test
    func TestFilter() throws {

        let model = dummyViewModel()
        #expect(model.dataManager.items.count == 178)
        let lhs = ListHeader.defaultListHeaders
        let result = lhs.map({ $0.filter(items: model.dataManager.items) })
        #expect(result.count == 10)
        #expect(result[0].count == 0)
        #expect(result[1].count == 0)
        #expect(result[2].count == 0)
        #expect(result[3].count == 18)
        #expect(result[4].count == 92)
        #expect(result[5].count == 60)
        #expect(result[6].count == 1)
        #expect(result[7].count == 1)
        #expect(result[8].count == 0)
        #expect(result[9].count == 6)
    }

    func split(headers: [ListHeader], itemList: [TaskItem]) -> [PartialList] {
        var result = [PartialList]()
        for lh in headers {
            result.append(PartialList(header: lh, list: lh.filter(items: itemList)))
        }

        assert(itemList.count == result.reduced)
        return result
    }

    @Test
    func testSplitting() throws {
        let model = dummyViewModel()
        let lhs = ListHeader.defaultListHeaders
        var splitted = split(headers: lhs, itemList: model.dataManager.items)
        #expect(splitted.reduced == model.dataManager.items.count)

        let graveyard: [TaskItem] = model.dataManager.list(which: .dead)
        splitted = split(headers: lhs, itemList: graveyard)
        #expect(splitted.reduced == graveyard.count)
    }
}
