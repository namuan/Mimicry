import Foundation
import Security

/// Manages Hugging Face authentication tokens.
///
/// Token resolution order:
/// 1. HF_TOKEN environment variable
/// 2. Existing token file under HF_HOME
/// 3. macOS Keychain (app-configured)
public actor AuthenticationProvider {
    private let configuration: HuggingFaceCacheConfiguration

    private static let keychainService = "com.audiobookstudio.huggingface"
    private static let keychainAccount = "hf_token"

    public init(configuration: HuggingFaceCacheConfiguration = HuggingFaceCacheConfiguration()) {
        self.configuration = configuration
    }

    /// Resolve the current authentication token.
    public func resolveToken() -> String? {
        // 1. Environment variable
        if let envToken = ProcessInfo.processInfo.environment["HF_TOKEN"],
           !envToken.isEmpty {
            return envToken
        }

        // 2. Token file under HF_HOME
        let tokenFile = configuration.homeDirectory.appendingPathComponent("token")
        if let rawToken = try? String(contentsOf: tokenFile, encoding: .utf8) {
            let fileToken = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
            if !fileToken.isEmpty {
                return fileToken
            }
        }

        // 3. Keychain
        return Self.readFromKeychain()
    }

    /// Store a token in the Keychain.
    public func storeInKeychain(_ token: String) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }

        // Delete existing
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Remove the stored token from the Keychain.
    public func removeFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
        ]
        SecItemDelete(query as CFDictionary)
    }

    /// Check if a token is configured.
    public func hasToken() -> Bool {
        resolveToken() != nil
    }

    /// Get a masked version of the token for display.
    public func maskedToken() -> String? {
        guard let token = resolveToken() else { return nil }
        if token.count <= 8 {
            return String(repeating: "*", count: token.count)
        }
        return "\(token.prefix(4))...\(token.suffix(4))"
    }

    // MARK: - Keychain helpers

    private static func readFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return token
    }
}
