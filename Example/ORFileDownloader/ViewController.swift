//
//  ViewController.swift
//  ORFileDownloader
//
//  Created by Teleks on 09/07/2017.
//  Copyright (c) 2017 Teleks. All rights reserved.
//

import UIKit
import ORFileDownloader

class ViewController: UIViewController {

    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var ivPreview: UIImageView!
    
    var download: ORDownload? {
        didSet {
            refreshDownloadButtonTitle()
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToNotifications()
        
        refreshDownloadButtonTitle()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unsubscribeFromNotifications()
    }

    
    // MARK: - Setup
    
    func subscribeToNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onDownloadErrorNotification(_:)),
                                               name: NSNotification.Name.ORDownloadDidFail,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onDownloadFinishedNotification(_:)),
                                               name: NSNotification.Name.ORDownloadDidFinish,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onDownloadProgressUpdatedNotification(_:)),
                                               name: NSNotification.Name.ORDownloadDidUpdateProgress,
                                               object: nil)
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.ORDownloadDidFail, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.ORDownloadDidFinish, object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.ORDownloadDidUpdateProgress, object: nil)
    }
    
    
    // MARK: - Actions
    
    @IBAction func onDownloadButtonTouchUp(_ sender: Any) {
        
        guard let fileDownload = download else {
            showURLSelectionAlert()
            return
        }
        
        if fileDownload.isDownloading {
            fileDownload.pause()
        } else {
            fileDownload.resume()
        }
        
        refreshDownloadButtonTitle()
    }
    
    
    // MARK: - Private methods
    
    func downloadFile(atURL urlString: String) {
        guard let url = URL(string: urlString) else {
            showAlert("Error", message: "Your URL is broken")
            return
        }
        
        let download = ORDownload(url: url, onFinish: nil, onFail: nil, onProgress: nil)
        download.start()
        
        self.download = download
        
        refreshDownloadButtonTitle()
    }
    
    @IBAction func onCrashButtonTouchUp(_ sender: Any) {
        assert(false)
    }
    
    func refreshDownloadButtonTitle() {
        
        guard let dl = download else {
            downloadButton?.setTitle("Download", for: .normal)
            return
        }
        
        if dl.isDownloading {
            downloadButton?.setTitle("Pause", for: .normal)
        } else {
            downloadButton?.setTitle("Resume", for: .normal)
        }
    }
    
    
    // MARK: - Notification Handlers
    
    func onDownloadFinishedNotification(_ notification: Notification) {
        
        self.download = nil
        progressView.setProgress(0.0, animated: true)
        progressLabel.text = "0%";
        
        let fileURL = (notification.userInfo?[ORDownload.kFileURLFieldKey] as? URL)!
        showAlert("Congratulations", message: "Your file downloaded.\nCheck: \(fileURL)")
    }
    
    func onDownloadErrorNotification(_ notification: Notification) {
        
        self.download = nil
        progressView.progress = 0.0
        
        let error = (notification.userInfo?[ORDownload.kErrorFieldKey] as? Error)!
        showAlert("Error", message: error.localizedDescription)
    }
    
    func onDownloadProgressUpdatedNotification(_ notification: Notification) {
        let progress = (notification.userInfo?[ORDownload.kDownloadProgressFieldKey] as? Float)!
        
        DispatchQueue.main.async {
            self.progressView.setProgress(progress, animated: true)
            self.progressLabel.text = String(format: "%.1f%%", progress * 100.0)
        }
    }
 
    
    // MARK: - Helpers
    
    func showURLSelectionAlert() {
        
        let alertVC = UIAlertController(title: "File URL",
                                        message: "What file do you want to download?",
                                        preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let downloadAction = UIAlertAction(title: "Download", style: .default) { [weak self] (action) in
            let urlStr = (alertVC.textFields?.first?.text)!
            
            DispatchQueue.main.async {
                self?.downloadFile(atURL: urlStr)
            }
        }
        
        alertVC.addTextField { (textField) in
            textField.placeholder = "Please paste file URL here"
            textField.text = "http://epicwallpaperz.com/wallpaper-hd/spring-rain-image-On-wallpaper-hd.jpg"
        }
        
        alertVC.addAction(cancelAction)
        alertVC.addAction(downloadAction)
        
        present(alertVC, animated: true, completion: nil)
    }
    
    func showAlert(_ title: String, message: String) {
        let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertVC.addAction(okAction)
        present(alertVC, animated: true, completion: nil)
    }
    
}

