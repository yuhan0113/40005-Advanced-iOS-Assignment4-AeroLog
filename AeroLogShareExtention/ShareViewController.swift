//
//  ShareViewController.swift
//  AeroLog
//
//  Created by Yu-Han on 18/10/2025.
//

import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {
    
    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }
        
        if itemProvider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (item, error) in
                guard let self = self,
                      let text = item as? String else {
                    DispatchQueue.main.async {
                        self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                    }
                    return
                }
                
                // Extract flight code from shared text
                let flightCode = self.extractFlightCode(from: text)
                
                DispatchQueue.main.async {
                    if let flightCode = flightCode {
                        self.saveFlightCodeToUserDefaults(flightCode)
                        self.showSuccessMessage()
                    } else {
                        self.showErrorMessage()
                    }
                    
                    // Delay to show message before closing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                    }
                }
            }
        } else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }
    
    // MARK: - Helper Methods
    
    private func extractFlightCode(from text: String) -> String? {
        // Look for flight codes like QF123, AA456, etc.
        let pattern = #"[A-Z]{2,3}\d{1,4}"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex?.firstMatch(in: text, options: [], range: range) {
            let flightCode = (text as NSString).substring(with: match.range)
            return flightCode
        }
        
        return nil
    }
    
    private func saveFlightCodeToUserDefaults(_ flightCode: String) {
        let userDefaults = UserDefaults(suiteName: "group.com.yuhanchang.aerolog2025")
        userDefaults?.set(flightCode, forKey: "sharedFlightCode")
        userDefaults?.set(Date(), forKey: "sharedFlightCodeDate")
    }
    
    private func showSuccessMessage() {
        let alert = UIAlertController(title: "Flight Added",
                                    message: "Flight code saved to AeroLog. Open the app to add it to your flights.",
                                    preferredStyle: .alert)
        present(alert, animated: true)
    }
    
    private func showErrorMessage() {
        let alert = UIAlertController(title: "Invalid Flight Code",
                                    message: "Please share a valid flight code (e.g., QF123, AA456).",
                                    preferredStyle: .alert)
        present(alert, animated: true)
    }
}

