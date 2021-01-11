//
//  Download.swift
//  ORFileDownloader
//
//  Created by Nikita Egoshin on 9/7/17.
//

import UIKit


open class ORDownload : NSObject, URLSessionDownloadDelegate {
    
    public typealias DownloadFinishHandler = ((URL) -> Void)
    public typealias DownloadFailHandler = ((Error) -> Void)
    public typealias DownloadProgressHandler = ((Float) -> Void)
    
    
    // MARK: - Const & Var
    
    fileprivate static let kURLStorageKey: String = "kDownloadURLStorageKey"
    fileprivate static let kDownloadSessionIDStorageKey: String = "kDownloadSessionIDStorageKey"
    
    fileprivate let kIdentifier: String
    
    fileprivate var session: URLSession?
    fileprivate var task: URLSessionDownloadTask?
    
    fileprivate var url: URL
    public fileprivate(set) var isDownloading: Bool = false
    
    private var resumeData: Data?
    
    fileprivate var onDownloadFinished: DownloadFinishHandler? = nil
    fileprivate var onDownloadFailed: DownloadFailHandler? = nil
    fileprivate var onDownloadProgressUpdated: DownloadProgressHandler? = nil
    
    fileprivate var bgTaskEventsCompletionHandlers: (() -> Void)?
    
    
    // MARK: - Lifecycle
    
    public init(url: URL,
         onFinish: DownloadFinishHandler?,
         onFail: DownloadFailHandler?,
         onProgress: DownloadProgressHandler?) {
        
        self.url = url
        
        let storedSessionIdentifier = UserDefaults.standard.string(forKey: ORDownload.kDownloadSessionIDStorageKey)
        self.kIdentifier = storedSessionIdentifier ?? String.random
        
        UserDefaults.standard.set(url, forKey: ORDownload.kURLStorageKey)
        UserDefaults.standard.set(kIdentifier, forKey: ORDownload.kDownloadSessionIDStorageKey)
    }
    
    deinit {
    }
    
    
    // MARK: - Prepare Data
    
    private func configuration(identifier: String? = nil, withCredential credential: AccessCredential? = nil) -> URLSessionConfiguration? {
        let configuration = URLSessionConfiguration.background(withIdentifier: (identifier ?? kIdentifier))
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = true
        
        if var accessCredential = credential {
            let urlComps = URLComponents(string: url.absoluteString)
            
            if urlComps?.scheme != nil { accessCredential.urlProtocol = urlComps?.scheme }
            if urlComps?.host != nil { accessCredential.urlProtocol = urlComps?.host }
            if urlComps?.port != nil { accessCredential.port = urlComps?.port }
            
            if !accessCredential.isComplete {
                return nil
            }
            
            configuration.urlCredentialStorage = credentialStorage(with: accessCredential)
        }
        
        return configuration
    }
    
    private func credentialStorage(with credentialsData: AccessCredential) -> URLCredentialStorage {
        
        credentialsData.save()
        
        let credential = URLCredential(user: credentialsData.username,
                                       password: credentialsData.password,
                                       persistence: .forSession)
        
        let storage = URLCredentialStorage.shared
        let protectionSpace = URLProtectionSpace(host: credentialsData.host!,
                                                 port: credentialsData.port!,
                                                 protocol: credentialsData.urlProtocol,
                                                 realm: credentialsData.realm,
                                                 authenticationMethod: nil)
        storage.set(credential, for: protectionSpace)
        
        return storage
    }
    
    
    // MARK: - Operation control
    
    @discardableResult
    public func start(credential: AccessCredential? = nil) -> Bool {
        guard let configuration = configuration(withCredential: credential) else {
            logIssue("Failed to create configuration")
            return false
        }
        
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
        startTask()
        self.isDownloading = true
        
        return true
    }
    
    public func pause() {
        task?.cancel(byProducingResumeData: { [weak self] (data) in
            self?.resumeData = data
        })
        
        self.isDownloading = false
    }
    
    public func resume() {
        startTask()
        self.isDownloading = true
    }
    
    public func cancel() {
        task?.cancel()
    }
    
    
    // MARK: - Internal operations
    
    private func startTask() {
        guard session != nil else {
            logIssue("Unable to resume download: Session doesn't exist.")
            return
        }
        
        if nil == resumeData {
            cancel()
            task = session?.downloadTask(with: url)
        } else {
            task = session?.downloadTask(withResumeData: resumeData!)
        }
        
        task?.resume()
    }
    
    private func saveFile(_ from: URL, savingError: inout Error?) -> URL? {
        let filePath = "\(NSTemporaryDirectory())/\(String.random)"
        
        if FileManager.default.fileExists(atPath: filePath) {
            do {
                try FileManager.default.removeItem(atPath: filePath)
            } catch {
                logIssue("Failed to remove file. Reason: \(error.localizedDescription)")
            }
        }
        
        let fileURL = URL(fileURLWithPath: filePath)
        
        do {
            try FileManager.default.copyItem(at: from, to: fileURL)
        } catch {
            savingError = error
            return nil
        }
        
        return fileURL
    }
    
    
    // MARK: - Public handlers
    
    public static func handleEventsForBackgroundSession(with identifier: String, completion: @escaping (() -> Void)) {
        
        if let download = ORDownload.restoreDownload(withIdentifier: identifier) {
            download.bgTaskEventsCompletionHandlers = completion
        }
    }
    
    public static func restoreDownload(withIdentifier identifier: String? = nil) -> ORDownload? {
        guard let url = UserDefaults.standard.url(forKey: kURLStorageKey) else {
                
            return nil
        }
        
        let credential = AccessCredential.restore()
        let download = ORDownload(url: url, onFinish: nil, onFail: nil, onProgress: nil)
        
        if let configuration = download.configuration(identifier: identifier, withCredential: credential) {
            download.session = URLSession(configuration: configuration, delegate: download, delegateQueue: nil)
        }
        
        download.task?.resume()
        download.isDownloading = true
        
        return download
    }
    
    
    // MARK: - Logs
    
    private func logIssue(_ message: String) {
        #if ORDOWNLOADER_LOGS
            print(message)
        #endif
    }
    
    
    // MARK: - Notification Senders
    
    private func postNotification(_ name: Notification.Name, withUserInfo userInfo: [String : Any]) {
        DispatchQueue.main.async {
            let notification = Notification(name: name,
                                            object: self,
                                            userInfo: userInfo)
            
            NotificationCenter.default.post(notification)
        }
    }
    
    private func postDownloadFailNotification(for error: Error) {
        let userInfo = [ORDownload.kErrorFieldKey : error]
        postNotification(Notification.Name.ORDownloadDidFail, withUserInfo: userInfo)
        
        logIssue("Task failed with error: \(error.localizedDescription)")
    }
    
    private func postDownloadFinishedNotification(withFileURL fileURL: URL) {
        let userInfo = [ORDownload.kFileURLFieldKey : fileURL]
        postNotification(Notification.Name.ORDownloadDidFinish, withUserInfo: userInfo)
    }
    
    private func postDownloadProgressUpdateNotification(withProgress progress: Float) {
        let userInfo = [ORDownload.kDownloadProgressFieldKey : progress]
        postNotification(Notification.Name.ORDownloadDidUpdateProgress, withUserInfo: userInfo)
    }
    
    
    // MARK: - URLSessionDownloadDelegate
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        if self.task == nil {
            self.task = downloadTask as URLSessionDownloadTask
        }
        
        let progress: Float = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        UIApplication.shared.applicationIconBadgeNumber = Int(progress)
        
        postDownloadProgressUpdateNotification(withProgress: progress)
        onDownloadProgressUpdated?(progress)
    }
    
    private func invalidate() {
        AccessCredential.clearStorage()
        UserDefaults.standard.removeObject(forKey: ORDownload.kURLStorageKey)
        UserDefaults.standard.removeObject(forKey: ORDownload.kDownloadSessionIDStorageKey)
        session?.invalidateAndCancel()
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        isDownloading = false
        
        if let err = downloadTask.error {
            postDownloadFailNotification(for: err)
            onDownloadFailed?(err)
        } else if let res = downloadTask.response as? HTTPURLResponse,
            res.statusCode == 200 {
            
            var error: Error?
            let fileURL = saveFile(location, savingError: &error)
            
            if error == nil {
                postDownloadFinishedNotification(withFileURL: fileURL!)
                onDownloadFinished?(fileURL!)
            } else {
                postDownloadFailNotification(for: error!)
                onDownloadFailed?(error!)
            }
        }
        
        invalidate()
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if let err = error {
            let nsError = err as NSError
            
            if nsError.code != NSURLErrorCancelled {
                postDownloadFailNotification(for: err)
                invalidate()
            }
        }
    }
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        let handler = bgTaskEventsCompletionHandlers
        bgTaskEventsCompletionHandlers = nil
        
        handler?()
    }
    
}
