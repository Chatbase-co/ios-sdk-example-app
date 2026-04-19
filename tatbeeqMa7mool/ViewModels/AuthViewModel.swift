//
//  AuthViewModel.swift
//  tatbeeqMa7mool
//

import CryptoKit
import Foundation
import ChatbaseSDK
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "tatbeeqMa7mool", category: "AuthViewModel")
private let userIdKey = "tatbeeqMa7mool.auth.userId"

@MainActor @Observable
final class AuthViewModel {
    let client: ChatbaseClient
    var userIdInput: String = ""
    var secretInput: String = ""
    private(set) var isWorking: Bool = false
    var errorMessage: String?
    private(set) var isIdentified: Bool
    private(set) var currentUserId: String?

    init(client: ChatbaseClient) {
        self.client = client
        if case .identified = client.authState {
            self.isIdentified = true
            self.currentUserId = UserDefaults.standard.string(forKey: userIdKey)
        } else {
            self.isIdentified = false
            self.currentUserId = nil
        }
    }

    func identify() async {
        let userId = userIdInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let secret = secretInput
        guard !userId.isEmpty, !secret.isEmpty else { return }

        isWorking = true
        errorMessage = nil
        do {
            let token = try signHS256(claims: ["user_id": userId], secret: secret)
            try await client.identify(token: token)
            UserDefaults.standard.set(userId, forKey: userIdKey)
            currentUserId = userId
            isIdentified = true
            secretInput = ""
            userIdInput = ""
        } catch {
            logger.error("identify failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        isWorking = false
    }

    func logout() {
        client.logout()
        UserDefaults.standard.removeObject(forKey: userIdKey)
        isIdentified = false
        currentUserId = nil
        secretInput = ""
        userIdInput = ""
        errorMessage = nil
    }
}

private func signHS256(claims: [String: Any], secret: String) throws -> String {
    let header: [String: Any] = ["alg": "HS256", "typ": "JWT"]
    let headerData = try JSONSerialization.data(withJSONObject: header, options: [.sortedKeys])
    let payloadData = try JSONSerialization.data(withJSONObject: claims, options: [.sortedKeys])
    let signingInput = "\(base64URL(headerData)).\(base64URL(payloadData))"
    let key = SymmetricKey(data: Data(secret.utf8))
    let signature = HMAC<SHA256>.authenticationCode(for: Data(signingInput.utf8), using: key)
    return "\(signingInput).\(base64URL(Data(signature)))"
}

private func base64URL(_ data: Data) -> String {
    data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}
