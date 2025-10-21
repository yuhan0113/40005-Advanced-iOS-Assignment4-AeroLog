//
//  PreviewProvider.swift
//  AeroLogQuickLookExtension
//
//  Created by 張宇漢 on 20/10/2025.
//

import QuickLook
import UniformTypeIdentifiers

class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    

    /*
     Use a QLPreviewProvider to provide data-based previews.
     
     To set up your extension as a data-based preview extension:

     - Modify the extension's Info.plist by setting
       <key>QLIsDataBasedPreview</key>
       <true/>
     
     - Add the supported content types to QLSupportedContentTypes array in the extension's Info.plist.

     - Remove
       <key>NSExtensionMainStoryboard</key>
       <string>MainInterface</string>
     
       and replace it by setting the NSExtensionPrincipalClass to this class, e.g.
       <key>NSExtensionPrincipalClass</key>
       <string>$(PRODUCT_MODULE_NAME).PreviewProvider</string>
     
     - Implement providePreview(for:)
     */
    
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let contentType = UTType.plainText
        let text = (try? String(contentsOf: request.fileURL, encoding: .utf8)) ?? ""
        let code = extractFlightCode(from: text)

        if let code {
            let ud = UserDefaults(suiteName: "group.com.yuhanchang.aerolog2025")
            ud?.set(code, forKey: "sharedFlightCode")
            ud?.set(Date(), forKey: "sharedFlightCodeDate")
            ud?.synchronize()
        }

        let message: String
        if let code { message = "Flight \(code) saved to AeroLog. Open the app to add it." }
        else { message = "No valid flight code found. Put something like QF123 in the file." }

        let reply = QLPreviewReply(dataOfContentType: contentType, contentSize: .zero) { replyToUpdate in
            replyToUpdate.stringEncoding = .utf8
            return Data(message.utf8)
        }
        return reply
    }

    private func extractFlightCode(from text: String) -> String? {
        let pattern = #"[A-Z]{2,3}\d{1,4}"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        if let match = regex?.firstMatch(in: text, range: range) {
            return (text as NSString).substring(with: match.range)
        }
        return nil
    }

}
