//
//  NotificationViewController.swift
//  AeroLogNotificationContent
//
//  Created by 張宇漢 on 20/10/2025.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var label: UILabel?
    private var flightCode: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        let content = notification.request.content
        self.flightCode = (content.userInfo["flightCode"] as? String) ?? nil
        let dep = (content.userInfo["departure"] as? String) ?? ""
        let arr = (content.userInfo["arrival"] as? String) ?? ""
        let time = (content.userInfo["departureTime"] as? String) ?? ""
        let subtitle = content.subtitle
        self.label?.text = "\(subtitle) — \(dep) → \(arr) at \(time)"
    }

    func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        switch response.actionIdentifier {
        case "add.flight":
            if let code = flightCode {
                let ud = UserDefaults(suiteName: "group.com.yuhanchang.aerolog2025")
                ud?.set(code, forKey: "sharedFlightCode")
                ud?.set(Date(), forKey: "sharedFlightCodeDate")
            }
            completion(.dismissAndForwardAction)
        case "dismiss.flight":
            completion(.dismiss)
        default:
            completion(.doNotDismiss)
        }
    }

}
