//
//  FilesRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 21/12/2023.
//

import Foundation


// Helper function to get the documents directory
func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}
