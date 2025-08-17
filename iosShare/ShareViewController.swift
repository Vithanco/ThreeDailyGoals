import Foundation.NSItemProvider
import Social
import SwiftUI
import UIKit
//
//  ShareViewController.swift
//  iosShare
//
//  Created by Klaus Kneupner on 05/08/2025.
//
import UniformTypeIdentifiers

@objc(ShareViewController)
public class ShareViewController: UIViewController {

    public override func viewDidLoad() {
        super.viewDidLoad()
        guard
            let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
            let itemProvider = extensionItem.attachments?.first
        else {
            self.close()
            return
        }
        if itemProvider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) {
                (providedText, error) in
                if error != nil {
                    self.close()
                    return
                }
                guard let text = providedText as? String else {
                    self.close()
                    return
                }
                DispatchQueue.main.async {
                    let preferences = CloudPreferences(testData: false)
                    let container = sharedModelContainer(inMemory: false, withCloud: true)

                    let rootView = ShareExtensionView(text: text)
                        .environmentObject(preferences)
                        .modelContainer(container)

                    let contentView = UIHostingController(rootView: rootView)
                    self.addChild(contentView)
                    self.view.addSubview(contentView.view)

                    // set up constraints
                    contentView.view.translatesAutoresizingMaskIntoConstraints = false
                    contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                    contentView.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
                    contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
                    contentView.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
                }
            }
        } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (providedURL, error) in
                if error != nil {
                    self.close()
                    return
                }
                guard let url = providedURL as? URL else {
                    self.close()
                    return
                }

                DispatchQueue.main.async {
                    let preferences = CloudPreferences(testData: false)
                    let container = sharedModelContainer(inMemory: false, withCloud: true)

                    let rootView = ShareExtensionView(url: url.absoluteString)
                        .environmentObject(preferences)
                        .modelContainer(container)

                    let contentView = UIHostingController(rootView: rootView)
                    self.addChild(contentView)
                    self.view.addSubview(contentView.view)

                    // set up constraints
                    contentView.view.translatesAutoresizingMaskIntoConstraints = false
                    contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                    contentView.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
                    contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
                    contentView.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
                }
            }

        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("close"), object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.close()
            }
        }
    }

    func close() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

}
