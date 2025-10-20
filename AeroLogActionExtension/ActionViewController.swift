//
//  ActionViewController.swift
//  AeroLogActionExtension
//
//  Created by Yu-Han on 20/10/2025.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Process the input immediately
        processInput()
    }
    
    private func processInput() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            completeRequest()
            return
        }
        
        // Check for text
        if itemProvider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (item, error) in
                DispatchQueue.main.async {
                    if let text = item as? String {
                        self?.processText(text)
                    } else {
                        self?.completeRequest()
                    }
                }
            }
        } else {
            completeRequest()
        }
    }
    
    private func processText(_ text: String) {
        // Extract flight code
        let flightCode = extractFlightCode(from: text)
        
        if let flightCode = flightCode {
            // Save to UserDefaults
            saveFlightCode(flightCode)
            
            // Show success message
            showAlert(title: "Flight Added", message: "Flight \(flightCode) added to AeroLog!")
        } else {
            // Show error message
            showAlert(title: "No Flight Code", message: "No valid flight code found in the selected text.")
        }
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
    
    private func saveFlightCode(_ flightCode: String) {
        let userDefaults = UserDefaults(suiteName: "group.com.yuhanchang.aerolog2025")
        userDefaults?.set(flightCode, forKey: "sharedFlightCode")
        userDefaults?.set(Date(), forKey: "sharedFlightCodeDate")
        userDefaults?.synchronize()
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.completeRequest()
        })
        present(alert, animated: true)
    }
    
    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    @IBAction func done() {
        completeRequest()
    }
}
