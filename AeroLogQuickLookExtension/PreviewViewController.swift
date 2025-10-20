//
//  PreviewViewController.swift
//  AeroLogQuickLookExtension
//
//  Created by 張宇漢 on 20/10/2025.
//

import UIKit
import QuickLook
import UniformTypeIdentifiers

class PreviewViewController: UIViewController, QLPreviewingController {
    @IBOutlet private weak var messageLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Fallback: if outlet isn't connected, try to find a label
        if messageLabel == nil {
            messageLabel = view.subviews.compactMap { $0 as? UILabel }.first
        }
    }

    func preparePreviewOfFile(at url: URL) async throws {
        // Read text content
        let text: String
        do {
            text = try String(contentsOf: url, encoding: .utf8)
        } catch {
            await updateLabel("Cannot read file contents.")
            return
        }

        // Extract flight code like QF123, AA456, etc.
        let flightCode = extractFlightCode(from: text)

        guard let code = flightCode else {
            await updateLabel("No valid flight code found in file.")
            return
        }

        // Save to shared App Group so main app can pick it up
        let userDefaults = UserDefaults(suiteName: "group.com.yuhanchang.aerolog2025")
        userDefaults?.set(code, forKey: "sharedFlightCode")
        userDefaults?.set(Date(), forKey: "sharedFlightCodeDate")
        userDefaults?.synchronize()

        await updateLabel("Flight \(code) saved to AeroLog. Open the app to add it.")
    }

    private func extractFlightCode(from text: String) -> String? {
        let pattern = #"[A-Z]{2,3}\d{1,4}"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: text.utf16.count)
        if let match = regex?.firstMatch(in: text, options: [], range: range) {
            return (text as NSString).substring(with: match.range)
        }
        return nil
    }

    @MainActor
    private func updateLabel(_ text: String) {
        messageLabel?.text = text
    }
}
