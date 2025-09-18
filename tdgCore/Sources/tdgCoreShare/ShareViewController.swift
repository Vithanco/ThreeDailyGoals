import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

open class ShareViewController: BaseViewController {

    private let container: ModelContainer
    private let preferences = CloudPreferences(testData: false, timeProvider: RealTimeProvider())

    public init() {
        // For share extensions, we'll use a simple in-memory container
        // since we don't need CloudKit sync for share operations
        switch sharedModelContainer(inMemory: true, withCloud: false) {
        case .success(let container):
            self.container = container
        case .failure:
            // Fallback to a basic container if there's an error
            self.container = try! ModelContainer(
                for: TaskItem.self, Attachment.self, Comment.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
