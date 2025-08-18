import Foundation
import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
    import UIKit
    public typealias BaseViewController = UIViewController
    public typealias HostingController = UIHostingController
#elseif os(macOS)
    import AppKit
    public typealias BaseViewController = NSViewController
    public typealias HostingController = NSHostingController
#endif

public class ShareViewController: BaseViewController {

    private lazy var preferences = CloudPreferences(testData: false)
    private lazy var container = sharedModelContainer(inMemory: false, withCloud: true)

    public override func viewDidLoad() {
        super.viewDidLoad()

        guard
            let extItem = extensionContext?.inputItems.first as? NSExtensionItem,
            let provider = extItem.attachments?.first
        else {
            close()
            return
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("close"), object: nil, queue: nil) { _ in
            Task { @MainActor in self.close() }
        }

        Task { @MainActor in
            do {
                guard let payload = try await ShareFlow.resolve(from: provider) else {
                    close()
                    return
                }
                let root = ShareFlow.makeView(for: payload, preferences: preferences, container: container)
                presentRoot(root)
            } catch {
                close()
            }
        }
    }

    @MainActor
    private func presentRoot<Content: View>(_ content: Content) {
        let host = HostingController(rootView: content)
        addChild(host)
        view.addSubview(host.view)

        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        #if os(iOS)
            host.didMove(toParent: self)
        #endif
    }

    func close() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
