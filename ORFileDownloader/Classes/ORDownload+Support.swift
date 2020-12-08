//
//  Download+FieldKeys.swift
//  ORFileDownloader
//
//  Created by Nikita Egoshin on 9/7/17.
//

import Foundation


extension String {
    static var random: String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
}

public extension Notification.Name {
    static let ORDownloadDidFinish = Notification.Name(rawValue: "ORDownloadDidFinish")
    static let ORDownloadDidFail = Notification.Name(rawValue: "ORDownloadDidFail")
    static let ORDownloadDidUpdateProgress = Notification.Name(rawValue: "ORDownloadDidUpdateProgress")
}


// MARK: - Field Keys

public extension ORDownload {
    static let kErrorFieldKey = "error"
    static let kFileURLFieldKey = "fileURL"
    static let kDownloadProgressFieldKey = "progress"
}
