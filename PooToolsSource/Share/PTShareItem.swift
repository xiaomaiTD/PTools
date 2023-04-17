//
//  PTShareItem.swift
//  PTNetworkTesting
//
//  Created by 邓杰豪 on 7/3/23.
//

import UIKit

open class PTShareItem: NSObject,UIActivityItemSource {
    let title: String
    let content: String
    let url: URL?
    
    public init(title: String, content: String, url: URL? = nil) {
        self.title = title
        self.content = content
        self.url = url
    }
    
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        switch activityType {
        case .postToFacebook?:
            if url != nil {
                return "\(title)\n\(content)\n\(url!)"
            } else {
                return "\(title)\n\(content)"
            }
        case .postToTwitter?:
            if url != nil {
                return "\(title) \(url!)"
            } else {
                return "\(title)"
            }
        case .message?:
            if url != nil {
                return "\(title)\n\(content)\n\(url!)"
            } else {
                return "\(title)\n\(content)"
            }
        default:
            return url
        }
    }
}

open class PTShare {
    public static let share = PTShare()
    
    public func share(shareItems items:[Any]) {
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        PTUtils.getCurrentVC().present(activityViewController, animated: true)
    }
}
