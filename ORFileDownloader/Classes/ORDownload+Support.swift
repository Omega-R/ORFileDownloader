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
    public static let ORDownloadDidFinish = Notification.Name(rawValue: "ORDownloadDidFinish")
    public static let ORDownloadDidFail = Notification.Name(rawValue: "ORDownloadDidFail")
    public static let ORDownloadDidUpdateProgress = Notification.Name(rawValue: "ORDownloadDidUpdateProgress")
}


// MARK: - Field Keys

public extension ORDownload {
    public static let kErrorFieldKey = "error"
    public static let kFileURLFieldKey = "fileURL"
    public static let kDownloadProgressFieldKey = "progress"
}
