import Foundation
import Supabase

/// One client for the whole app — mirrors the web app's "single `db` instance"
/// rule. Never create a second SupabaseClient.
final class Supa {
    static let shared = Supa()
    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey
        )
    }
}