import Foundation
import AuthenticationServices

// MARK: - Clerk Configuration
struct ClerkConfig {
    // Replace with your actual Clerk publishable key
    static let publishableKey = "pk_test_YOUR_CLERK_PUBLISHABLE_KEY"

    // Replace with your Clerk Frontend API URL
    static let frontendAPIURL = "https://YOUR_CLERK_FRONTEND_API.clerk.accounts.dev"

    // OAuth callback URL scheme (add to Info.plist)
    static let callbackURLScheme = "minimaltodo"
}

// MARK: - User Model
struct ClerkUser: Codable, Identifiable {
    let id: String
    let email: String?
    let firstName: String?
    let lastName: String?
    let imageUrl: String?

    var displayName: String {
        if let first = firstName, let last = lastName {
            return "\(first) \(last)"
        }
        return firstName ?? email ?? "User"
    }
}

// MARK: - Auth State
enum AuthState {
    case loading
    case signedOut
    case signedIn(ClerkUser)
}

// MARK: - Auth Manager
@MainActor
class AuthManager: NSObject, ObservableObject {
    static let shared = AuthManager()

    @Published var authState: AuthState = .loading
    @Published var isLoading = false
    @Published var error: String?

    private var currentSession: ASWebAuthenticationSession?
    private let keychain = KeychainHelper.shared

    var currentUser: ClerkUser? {
        if case .signedIn(let user) = authState {
            return user
        }
        return nil
    }

    var isSignedIn: Bool {
        if case .signedIn = authState {
            return true
        }
        return false
    }

    var userId: String? {
        currentUser?.id
    }

    override private init() {
        super.init()
        Task {
            await checkExistingSession()
        }
    }

    // MARK: - Public Methods

    func signInWithEmail(email: String, password: String) async {
        isLoading = true
        error = nil

        do {
            let url = URL(string: "\(ClerkConfig.frontendAPIURL)/v1/client/sign_ins")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(ClerkConfig.publishableKey, forHTTPHeaderField: "Authorization")

            let body = [
                "identifier": email,
                "password": password
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }

            if httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(ClerkSignInResponse.self, from: data)
                await handleSignInSuccess(response: result)
            } else {
                let errorResponse = try? JSONDecoder().decode(ClerkErrorResponse.self, from: data)
                throw AuthError.signInFailed(errorResponse?.errors.first?.message ?? "Sign in failed")
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func signUpWithEmail(email: String, password: String, firstName: String? = nil, lastName: String? = nil) async {
        isLoading = true
        error = nil

        do {
            let url = URL(string: "\(ClerkConfig.frontendAPIURL)/v1/client/sign_ups")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(ClerkConfig.publishableKey, forHTTPHeaderField: "Authorization")

            var body: [String: Any] = [
                "email_address": email,
                "password": password
            ]

            if let firstName = firstName {
                body["first_name"] = firstName
            }
            if let lastName = lastName {
                body["last_name"] = lastName
            }

            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }

            if httpResponse.statusCode == 200 {
                // Sign up successful, now sign in
                await signInWithEmail(email: email, password: password)
            } else {
                let errorResponse = try? JSONDecoder().decode(ClerkErrorResponse.self, from: data)
                throw AuthError.signUpFailed(errorResponse?.errors.first?.message ?? "Sign up failed")
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func signInWithApple() async {
        isLoading = true
        error = nil

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self

        controller.performRequests()
    }

    func signOut() async {
        // Clear stored tokens
        keychain.delete(key: "clerk_session_token")
        keychain.delete(key: "clerk_user")

        // Clear Convex auth
        ConvexClient.shared.setAuthToken(nil)

        authState = .signedOut
    }

    // MARK: - Private Methods

    private func checkExistingSession() async {
        if let token = keychain.get(key: "clerk_session_token"),
           let userData = keychain.getData(key: "clerk_user"),
           let user = try? JSONDecoder().decode(ClerkUser.self, from: userData) {
            // Validate token
            do {
                let isValid = try await validateToken(token)
                if isValid {
                    ConvexClient.shared.setAuthToken(token)
                    authState = .signedIn(user)
                    return
                }
            } catch {
                // Token invalid, sign out
            }
        }

        authState = .signedOut
    }

    private func validateToken(_ token: String) async throws -> Bool {
        let url = URL(string: "\(ClerkConfig.frontendAPIURL)/v1/me")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }

        return httpResponse.statusCode == 200
    }

    private func handleSignInSuccess(response: ClerkSignInResponse) async {
        guard let session = response.client?.sessions.first,
              let sessionToken = session.lastActiveToken?.jwt else {
            error = "Failed to get session token"
            return
        }

        let user = ClerkUser(
            id: session.user.id,
            email: session.user.emailAddresses.first?.emailAddress,
            firstName: session.user.firstName,
            lastName: session.user.lastName,
            imageUrl: session.user.imageUrl
        )

        // Store credentials
        keychain.set(key: "clerk_session_token", value: sessionToken)
        if let userData = try? JSONEncoder().encode(user) {
            keychain.setData(key: "clerk_user", value: userData)
        }

        // Set up Convex
        ConvexClient.shared.setAuthToken(sessionToken)

        authState = .signedIn(user)
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthManager: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Handle Apple Sign In
                let userIdentifier = appleIDCredential.user

                if let identityToken = appleIDCredential.identityToken,
                   let tokenString = String(data: identityToken, encoding: .utf8) {
                    // Send to Clerk for verification
                    await handleAppleSignIn(
                        identityToken: tokenString,
                        userIdentifier: userIdentifier,
                        email: appleIDCredential.email,
                        firstName: appleIDCredential.fullName?.givenName,
                        lastName: appleIDCredential.fullName?.familyName
                    )
                }
            }
            isLoading = false
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    private func handleAppleSignIn(identityToken: String, userIdentifier: String, email: String?, firstName: String?, lastName: String?) async {
        do {
            let url = URL(string: "\(ClerkConfig.frontendAPIURL)/v1/client/sign_ins")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(ClerkConfig.publishableKey, forHTTPHeaderField: "Authorization")

            let body: [String: Any] = [
                "strategy": "oauth_apple",
                "identifier": userIdentifier,
                "token": identityToken
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw AuthError.signInFailed("Apple Sign In failed")
            }

            let result = try JSONDecoder().decode(ClerkSignInResponse.self, from: data)
            await handleSignInSuccess(response: result)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Response Types

struct ClerkSignInResponse: Codable {
    let client: ClerkClient?
}

struct ClerkClient: Codable {
    let sessions: [ClerkSession]
}

struct ClerkSession: Codable {
    let user: ClerkSessionUser
    let lastActiveToken: ClerkToken?

    enum CodingKeys: String, CodingKey {
        case user
        case lastActiveToken = "last_active_token"
    }
}

struct ClerkSessionUser: Codable {
    let id: String
    let firstName: String?
    let lastName: String?
    let emailAddresses: [ClerkEmailAddress]
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case emailAddresses = "email_addresses"
        case imageUrl = "image_url"
    }
}

struct ClerkEmailAddress: Codable {
    let emailAddress: String

    enum CodingKeys: String, CodingKey {
        case emailAddress = "email_address"
    }
}

struct ClerkToken: Codable {
    let jwt: String
}

struct ClerkErrorResponse: Codable {
    let errors: [ClerkError]
}

struct ClerkError: Codable {
    let message: String
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidResponse
    case signInFailed(String)
    case signUpFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .signInFailed(let message):
            return message
        case .signUpFailed(let message):
            return message
        }
    }
}

// MARK: - Keychain Helper

class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    func set(key: String, value: String) {
        if let data = value.data(using: .utf8) {
            setData(key: key, value: data)
        }
    }

    func setData(key: String, value: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: value
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func get(key: String) -> String? {
        if let data = getData(key: key) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    func getData(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
