import Foundation
import SwiftData
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

    private let container = sharedModelContainer(inMemory: false, withCloud: false)
    private let preferences = CloudPreferences(testData: false)

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

        Task {
            do {
                guard let payload = try await ShareFlow.resolve(from: provider) else {
                    await MainActor.run { self.close() }
                    return
                }
                await MainActor.run {
                    let shareView = self.createShareView(for: payload)
                    self.presentRoot(shareView)
                }
            } catch {
                await MainActor.run { self.close() }
            }
        }
    }

    @MainActor
    private func createShareView(for payload: SharePayload) -> ShareExtensionView {
        switch payload {
        case .text(let text):
            return ShareExtensionView(text: text)
        case .url(let url):
            return ShareExtensionView(url: url)
        case .attachment(let fileURL, let contentType):
            return ShareExtensionView(fileURL: fileURL, contentType: contentType)
        }
    }

    @MainActor
    private func presentRoot<Content: View>(_ content: Content) {
        let host = HostingController(
            rootView:
                content
                .modelContainer(container)
                .environment(preferences)
        )
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
