import Foundation
import Security
import CommonCrypto
import LocalAuthentication

/// Mobile Security Configuration
class SecurityConfig {
    static let shared = SecurityConfig()
    private init() {}
    
    // MARK: - Security Settings
    
    struct SecuritySettings {
        // Jailbreak Detection
        static let enableJailbreakDetection = true
        static let jailbreakAction: SecurityAction = .terminate
        
        // SSL Pinning
        static let enableSSLPinning = true
        static let pinnedDomains = [
            "api.example.com": ["sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="],
            "auth.example.com": ["sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="]
        ]
        
        // Data Protection
        static let dataProtectionLevel: FileProtectionType = .complete
        static let keySecurityLevel = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        
        // Biometric Authentication
        static let enableBiometrics = true
        static let biometricReason = "Authenticate to access secure features"
        
        // Screenshot Protection
        static let preventScreenshots = true
        
        // Pasteboard Protection
        static let securePasteboard = true
        
        // Debug Protection
        static let preventDebugger = true
        
        // Runtime Integrity
        static let enableIntegrityChecks = true
        
        // Network Security
        static let enforceHTTPS = true
        static let allowedTLSVersions: [SSLProtocol] = [.tlsProtocol12, .tlsProtocol13]
    }
    
    // MARK: - Security Actions
    
    enum SecurityAction {
        case terminate
        case warn
        case block
        case report
    }
    
    // MARK: - Security Checks
    
    /// Check for jailbreak indicators
    func checkJailbreak() -> Bool {
        if SecuritySettings.enableJailbreakDetection {
            let paths = [
                "/Applications/Cydia.app",
                "/Library/MobileSubstrate/MobileSubstrate.dylib",
                "/bin/bash",
                "/usr/sbin/sshd",
                "/etc/apt",
                "/private/var/lib/apt/"
            ]
            
            for path in paths {
                if FileManager.default.fileExists(atPath: path) {
                    handleSecurityViolation(.jailbreak)
                    return true
                }
            }
            
            // Check for suspicious permissions
            if canWriteToSystemDirectories() {
                handleSecurityViolation(.jailbreak)
                return true
            }
        }
        return false
    }
    
    /// Configure SSL certificate pinning
    func configureSSLPinning() {
        if SecuritySettings.enableSSLPinning {
            let configuration = URLSessionConfiguration.default
            configuration.urlCache = nil
            
            class PinningURLSessionDelegate: NSObject, URLSessionDelegate {
                func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                              completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
                    guard let serverTrust = challenge.protectionSpace.serverTrust,
                          let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0),
                          let serverPublicKey = SecCertificateCopyKey(serverCertificate),
                          let serverPublicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) else {
                        completionHandler(.cancelAuthenticationChallenge, nil)
                        return
                    }
                    
                    let pinnedKeys = SecuritySettings.pinnedDomains[challenge.protectionSpace.host] ?? []
                    let serverKeyHash = (serverPublicKeyData as NSData).sha256()
                    
                    if pinnedKeys.contains(serverKeyHash) {
                        completionHandler(.useCredential, URLCredential(trust: serverTrust))
                    } else {
                        handleSecurityViolation(.sslPinningFailure)
                        completionHandler(.cancelAuthenticationChallenge, nil)
                    }
                }
            }
        }
    }
    
    /// Configure data protection
    func configureDataProtection() {
        // Set file protection
        let fileManager = FileManager.default
        if let documentPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? (documentPath as NSURL).setResourceValue(
                SecuritySettings.dataProtectionLevel,
                forKey: .fileProtectionKey
            )
        }
        
        // Configure keychain settings
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccessible as String: SecuritySettings.keySecurityLevel
        ]
        SecItemAdd(keychainQuery as CFDictionary, nil)
    }
    
    /// Configure biometric authentication
    func configureBiometrics(completion: @escaping (Bool, Error?) -> Void) {
        if SecuritySettings.enableBiometrics {
            let context = LAContext()
            var error: NSError?
            
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: SecuritySettings.biometricReason
                ) { success, error in
                    completion(success, error)
                }
            } else {
                completion(false, error)
            }
        }
    }
    
    /// Configure runtime protections
    func configureRuntimeProtections() {
        if SecuritySettings.preventScreenshots {
            DispatchQueue.main.async {
                UIApplication.shared.windows.first?.makeSecure()
            }
        }
        
        if SecuritySettings.securePasteboard {
            UIPasteboard.general.setItems([], options: [
                .localOnly: true,
                .expirationDate: Date(timeIntervalSinceNow: 60)
            ])
        }
        
        if SecuritySettings.preventDebugger {
            enableDebuggerDetection()
        }
    }
    
    // MARK: - Helper Methods
    
    private func canWriteToSystemDirectories() -> Bool {
        let path = "/private/jailbreak.txt"
        do {
            try "test".write(toFile: path, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
    }
    
    private func enableDebuggerDetection() {
        #if DEBUG
        return
        #else
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        
        let status = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        if status == 0 && (info.kp_proc.p_flag & P_TRACED) != 0 {
            handleSecurityViolation(.debuggerDetected)
        }
        #endif
    }
    
    // MARK: - Security Violation Handling
    
    enum SecurityViolationType {
        case jailbreak
        case sslPinningFailure
        case debuggerDetected
        case integrityFailure
        case runtimeManipulation
    }
    
    private func handleSecurityViolation(_ type: SecurityViolationType) {
        // Log security violation
        logSecurityViolation(type)
        
        // Take appropriate action based on settings
        switch SecuritySettings.jailbreakAction {
        case .terminate:
            exit(0)
        case .warn:
            NotificationCenter.default.post(
                name: NSNotification.Name("SecurityViolationWarning"),
                object: nil,
                userInfo: ["type": type]
            )
        case .block:
            disableAppFunctionality()
        case .report:
            reportSecurityViolation(type)
        }
    }
    
    private func logSecurityViolation(_ type: SecurityViolationType) {
        // Implement secure logging
    }
    
    private func disableAppFunctionality() {
        // Implement app functionality restriction
    }
    
    private func reportSecurityViolation(_ type: SecurityViolationType) {
        // Implement security violation reporting
    }
}

// MARK: - Extensions

extension UIWindow {
    func makeSecure() {
        if SecuritySettings.preventScreenshots {
            DispatchQueue.main.async {
                self.makeKey()
                self.isHidden = false
                self.layer.superlayer?.allowsGroupOpacity = false
            }
        }
    }
}

extension NSData {
    func sha256() -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(bytes, CC_LONG(length), &hash)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
