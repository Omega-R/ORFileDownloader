//
//  ViewController.swift
//  ORFileDownloader
//
//  Created by Nikita Egoshin on 09/07/2017.
//  Copyright (c) 2017 Omega-R. All rights reserved.
//

import UIKit
import ORFileDownloader

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    fileprivate let kFileURLCell = "kFileURLCell"
    
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var ivPreview: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    var loadedFilesURLs: [String] = []
    
    var download: ORDownload? {
        didSet {
            refreshDownloadButtonTitle()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadedFilesURLs = (UserDefaults.standard.array(forKey: "kFileURLs") as? [String]) ?? []
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToNotifications()
        
        refreshDownloadButtonTitle()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unsubscribeFromNotifications()
        
        UserDefaults.standard.set(loadedFilesURLs, forKey: "kFileURLs")
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
    
    @IBAction func onShareButtonTouchUp(_ sender: Any) {
        
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
        
        loadedFilesURLs.append(fileURL.absoluteString)
        tableView.reloadData()
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
            textField.text = "http://static.mp3-you.com/RzhyVGVwRUQyUG45Wjk3aWRyYms2Zy8xNTA1MjM5OTk3L0wyRnlZMmhwZG1Vdk1EUXVNRGt1TWpBeE4xOHhNQzR3T1M0eU1ERTNYMjF3TXkxNWIzVXVibVYwTG5KaGNn/L2FyY2hpdmUvMDQuMDkuMjAxN18xMC4wOS4yMDE3X21wMy15b3UubmV0LnJhcg.mp3"
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
    
    func deleteFileAtIndex(_ fileIndex: Int) {
        loadedFilesURLs.remove(at: fileIndex)
        tableView.deleteRows(at: [IndexPath(row: fileIndex, section: 0)], with: .automatic)
    }
    
    func shareFileAtIndex(_ fileIndex: Int) {
        let urlStr = loadedFilesURLs[fileIndex]
        let url = URL(string: urlStr)
        
        let sharingVC = UIActivityViewController(activityItems: [url!], applicationActivities: nil)
        present(sharingVC, animated: true, completion: nil)
    }
    
    
    // MARK: - UITableViewDataSource/Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loadedFilesURLs.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let url = loadedFilesURLs[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: kFileURLCell)
        cell?.textLabel?.text = url.components(separatedBy: "/").last
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        shareFileAtIndex(indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            deleteFileAtIndex(indexPath.row)
        }
    }
    
}

