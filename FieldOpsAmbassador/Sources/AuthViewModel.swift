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

    var isManager: Bool { profile?.isManager ?? false }
    var isAdmin: Bool { profile?.isAdmin ?? false }
    var canAdmin: Bool { isManager || isAdmin }
    var myRegionId: Int? { profile?.regionId }

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

    func updateProfile(name: String, phone: String, address: String, shirtSize: String) async {
        guard let id = profile?.id else { return }
        busy = true; defer { busy = false }
        struct Update: Encodable {
            let name: String, phone: String, address: String, shirt_size: String
        }
        do {
            try await client
                .from("profiles")
                .update(Update(name: name, phone: phone, address: address, shirt_size: shirtSize))
                .eq("id", value: id.uuidString)
                .execute()
            await loadProfile(userId: id)
        } catch {
            errorMessage = error.localizedDescription
        }
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

            // Managers and ambassadors both use the app. Managers run their own
            // solo demos through the same flow and get the extra Admin tab.
            profile = p
            phase = .signedIn
        } catch {
            errorMessage = "Could not load your profile: \(error.localizedDescription)"
            phase = .signedOut
        }
    }
}