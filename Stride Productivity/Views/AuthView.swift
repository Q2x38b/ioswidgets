import SwiftUI

struct AuthView: View {
    @ObservedObject var authManager = AuthManager.shared
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo/Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.appAccent, Color.appAccentDark],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)

                            Image(systemName: "calendar")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: Color.appAccent.opacity(0.4), radius: 20, x: 0, y: 10)

                        Text("Stride")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(isSignUp ? "Create your account" : "Welcome back")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    // Form fields
                    VStack(spacing: 16) {
                        if isSignUp {
                            HStack(spacing: 12) {
                                CustomTextField(
                                    placeholder: "First name",
                                    text: $firstName,
                                    icon: "person"
                                )

                                CustomTextField(
                                    placeholder: "Last name",
                                    text: $lastName,
                                    icon: "person"
                                )
                            }
                        }

                        CustomTextField(
                            placeholder: "Email",
                            text: $email,
                            icon: "envelope",
                            keyboardType: .emailAddress
                        )

                        CustomTextField(
                            placeholder: "Password",
                            text: $password,
                            icon: "lock",
                            isSecure: true
                        )
                    }
                    .padding(.horizontal)

                    // Error message
                    if let error = authManager.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    // Sign in/up button
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                if isSignUp {
                                    await authManager.signUpWithEmail(
                                        email: email,
                                        password: password,
                                        firstName: firstName.isEmpty ? nil : firstName,
                                        lastName: lastName.isEmpty ? nil : lastName
                                    )
                                } else {
                                    await authManager.signInWithEmail(email: email, password: password)
                                }
                            }
                        } label: {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [Color.appAccent, Color.appAccentDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .cornerRadius(16)
                        }
                        .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                        .padding(.horizontal)

                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color(.systemGray4))
                                .frame(height: 1)
                            Text("or")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Rectangle()
                                .fill(Color(.systemGray4))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 32)

                        // Sign in with Google
                        Button {
                            Task {
                                await authManager.signInWithGoogle()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .font(.system(size: 20, weight: .medium))
                                Text("Continue with Google")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color(.systemGray6))
                            .foregroundStyle(.primary)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                        .disabled(authManager.isLoading)
                        .padding(.horizontal)
                    }

                    // Toggle sign up/sign in
                    Button {
                        withAnimation {
                            isSignUp.toggle()
                            authManager.error = nil
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundStyle(.secondary)
                            Text(isSignUp ? "Sign In" : "Sign Up")
                                .foregroundStyle(Color.appAccent)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }

                    Spacer()
                }
            }
            .background(Color(.systemBackground))
        }
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

#Preview {
    AuthView()
}
