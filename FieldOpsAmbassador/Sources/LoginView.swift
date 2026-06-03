import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.ink, Color(red: 0.11, green: 0.02, blue: 0.02), Theme.ink],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                // Monogram badge (no logo file — inline "PS" mark)
                Text("PS")
                    .font(.system(size: 26, weight: .heavy, design: .serif))
                    .italic()
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(Theme.brand, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Theme.brand.opacity(0.5), radius: 12, y: 4)

                VStack(spacing: 4) {
                    Text("FieldOps").font(.largeTitle.bold()).foregroundStyle(.white)
                    Text("Ambassador").font(.subheadline).foregroundStyle(.white.opacity(0.6))
                }

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding(12)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                        .onSubmit { Task { await auth.signIn(email: email, password: password) } }
                }

                if let err = auth.errorMessage {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(Theme.brand)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await auth.signIn(email: email, password: password) }
                } label: {
                    HStack {
                        if auth.busy { ProgressView().tint(.white) }
                        Text(auth.busy ? "Signing in…" : "Log In").bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.brand, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                }
                .disabled(auth.busy)
            }
            .padding(28)
            .frame(maxWidth: 420)
        }
    }
}