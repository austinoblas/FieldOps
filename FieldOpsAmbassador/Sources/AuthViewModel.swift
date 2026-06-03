import Foundation
import Supabase
import Observation

@MainActor
@Observable
final class AuthViewModel {
    enum Phase: Equatable { case loading, signedOut, signedIn }

    var phase: Phase = .loading
    var profile: Profile?
    var errorMessage: String?
    var busy = false

    private let client = Supa.shared.client

    /// Restore an existing session on launch (handles app relaunch / token refresh).
    func bootstrap() async {
        do {
            let session = try await client.auth.session
            await loadProfile(userId: session.user.id)
        } catch {
            phase = .signedOut
        }
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }
        busy = true; defer { busy = false }
        do {
            let session = try await client.auth.signIn(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
            await loadProfile(userId: session.user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        try? await client.auth.signOut()
        profile = nil
        phase = .signedOut
    }

    private func loadProfile(userId: UUID) async {
        do {
            let p: Profile = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value

            // This app is the ambassador field tool. Managers use the web admin
            // view — so we politely bounce them rather than show a broken UI.
            if p.isManager {
                errorMessage = "This app is for brand ambassadors. Managers, please use the web dashboard."
                try? await client.auth.signOut()
                phase = .signedOut
                return
            }

            profile = p
            phase = .signedIn
        } catch {
            errorMessage = "Could not load your profile: \(error.localizedDescription)"
            phase = .signedOut
        }
    }
}