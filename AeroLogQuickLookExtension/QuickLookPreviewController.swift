//
//  QuickLookPreviewController.swift
//  AeroLogQuickLookExtension
//
//  Created by Yu-Han on 20/10/2025.
//

import UIKit
import QuickLook
import MobileCoreServices

class QuickLookPreviewController: QLPreviewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the preview controller
        self.dataSource = self
        self.delegate = self
        
        // Add a custom button to add flight to AeroLog
        let addButton = UIBarButtonItem(
            title: "Add to AeroLog",
            style: .done,
            target: self,
            action: #selector(addToAeroLog)
        )
        
        self.navigationItem.rightBarButtonItem = addButton
    }
    
    @objc private func addToAeroLog() {
        // Extract flight code from the preview item
        if let previewItem = self.dataSource?.previewController(self, previewItemAt: 0) as? FlightPreviewItem {
            let flightCode = previewItem.flightCode
            
            // Save to UserDefaults
            let userDefaults = UserDefaults(suiteName: "group.com.yuhanchang.aerolog2025")
            userDefaults?.set(flightCode, forKey: "sharedFlightCode")
            userDefaults?.set(Date(), forKey: "sharedFlightCodeDate")
            userDefaults?.synchronize()
            
            // Show success message
            let alert = UIAlertController(
                title: "Flight Added",
                message: "Flight \(flightCode) added to AeroLog. Open the app to add it to your flights.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            })
            
            present(alert, animated: true)
        }
    }
}

// MARK: - QLPreviewControllerDataSource

extension QuickLookPreviewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        // Create a flight preview item from the extension context
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let _ = extensionItem.attachments?.first else {
            return FlightPreviewItem(flightCode: "QF123", flightInfo: "Sample Flight")
        }
        
        // For now, return a sample flight item
        // In a real implementation, you'd parse the file content
        return FlightPreviewItem(flightCode: "QF123", flightInfo: "Qantas Flight 123 - Sydney to Melbourne")
    }
}

// MARK: - QLPreviewControllerDelegate

extension QuickLookPreviewController: QLPreviewControllerDelegate {
    func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
        return .disabled
    }
}

// MARK: - Custom Preview Item

class FlightPreviewItem: NSObject, QLPreviewItem {
    let flightCode: String
    let flightInfo: String
    
    init(flightCode: String, flightInfo: String) {
        self.flightCode = flightCode
        self.flightInfo = flightInfo
    }
    
    var previewItemURL: URL? {
        // Create a temporary file with flight information
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(flightCode).flight"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        let content = """
        Flight: \(flightCode)
        Information: \(flightInfo)
        Date: \(Date())
        
        This flight has been added to AeroLog.
        """
        
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    var previewItemTitle: String? {
        return "Flight \(flightCode)"
    }
}
