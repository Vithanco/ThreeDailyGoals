import Foundation
import MCP
import SwiftData
import os
import tdgCoreMain
import tdgCoreWidget

private let logger = Logger(
    subsystem: Bundle.safeSubsystem,
    category: "MCPServer"
)

@MainActor
public final class TDGMCPServer {
    private let server: Server
    private let router: MCPToolRouter

    public init(container: ModelContainer, timeProvider: TimeProvider = RealTimeProvider()) {
        self.server = Server(
            name: "Three Daily Goals",
            version: "1.0.0",
            capabilities: .init(tools: .init(listChanged: false))
        )
        self.router = MCPToolRouter(container: container, timeProvider: timeProvider)
    }

    public func start() async throws {
        let router = self.router

        await server
            .withMethodHandler(ListTools.self) { _ in
                ListTools.Result(tools: allTools)
            }
            .withMethodHandler(CallTool.self) { params in
                try await router.handle(name: params.name, arguments: params.arguments)
            }

        let transport = StdioTransport()
        try await server.start(transport: transport)

        logger.info("Three Daily Goals MCP server started")

        await server.waitUntilCompleted()
    }
}
