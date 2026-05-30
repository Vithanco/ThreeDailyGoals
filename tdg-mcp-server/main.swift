//
//  main.swift
//  tdg-mcp-server
//
//  Created by Klaus Kneupner on 19/03/2026.
//

import Foundation
import tdgCoreMCP
import tdgCoreMain

@MainActor
func run() async throws {
    switch sharedModelContainer(inMemory: false, withCloud: false) {
    case .success(let container):
        let server = TDGMCPServer(container: container)
        try await server.start()
    case .failure(let error):
        fputs("Error: Failed to create model container: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
}

try await run()
