//
//  NewItemProducer.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 30/08/2025.
//

@MainActor
public protocol NewItemProducer {
    func produceNewItem() -> TaskItem?
    func removeItem(_ item: TaskItem)
}
