//
//  ArrayRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 04/01/2024.
//

import Foundation


extension Array where Element: Equatable{
    public static func - (left: Array<Element>, right: Array<Element>) -> Array<Element> {
        var result = Array<Element>()
        for ele in left {
            if !right.contains(ele) {
                result.append(ele)
            }
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
