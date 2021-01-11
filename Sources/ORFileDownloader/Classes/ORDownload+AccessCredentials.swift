//
//  Download+AccessCredentials.swift
//  ORFileDownloader
//
//  Created by Nikita Egoshin on 9/7/17.
//

import Foundation


extension ORDownload {
    public struct AccessCredential {
        
        private static let kStorageKey = "skAccessCredential"
        
        private static let kHost = "host"
        private static let kPort = "port"
        private static let kProtocol = "protocol"
        private static let kRealm = "realm"
        
        private static let kUsername = "username"
        private static let kPassword = "password"
        
        var host: String?
        var port: Int?
        var urlProtocol: String?
        let realm: String?
        
        let username: String
        let password: String
        
        var isComplete: Bool {
            return host != nil && port != nil
        }
        
        // MARK: - Access Credential Lifecycle
        
        init(username: String, password: String, realm: String? = nil) {
            self.username = username
            self.password = password
            self.realm = realm
        }
        
        fileprivate init?(_ dict: [String : Any]) {
            
            guard let username = dict[AccessCredential.kUsername] as? String,
                let password = dict[AccessCredential.kPassword] as? String else {
                    
                    return nil
            }
            
            self.username = username
            self.password = password
            
            self.host = dict[AccessCredential.kHost] as? String
            self.port = dict[AccessCredential.kPort] as? Int
            self.urlProtocol = dict[AccessCredential.kProtocol] as? String
            self.realm = dict[AccessCredential.kRealm] as? String
        }
        
        
        // MARK: - Access Credential Storage
        
        static func restore() -> AccessCredential? {
            let dict = UserDefaults.standard.dictionary(forKey: AccessCredential.kStorageKey)
            AccessCredential.clearStorage()
            
            return dict != nil ? AccessCredential(dict!) : nil
        }
        
        static func clearStorage() {
            UserDefaults.standard.removeObject(forKey: AccessCredential.kStorageKey)
        }
        
        func save() {
            var dict: [String : Any] = [
                AccessCredential.kUsername : username,
                AccessCredential.kPassword : password,
                ]
            
            if host != nil { dict[AccessCredential.kHost] = host! }
            if port != nil { dict[AccessCredential.kPort] = port! }
            if urlProtocol != nil { dict[AccessCredential.kProtocol] = urlProtocol! }
            if realm != nil { dict[AccessCredential.kRealm] = realm! }
            
            UserDefaults.standard.set(dict, forKey: AccessCredential.kStorageKey)
        }
    }
}
