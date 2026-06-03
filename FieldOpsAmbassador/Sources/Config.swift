import Foundation

/// Supabase connection config.
///
/// The anon key is a *public* client key — it is safe to ship in the app.
/// Row-Level Security on the database is what actually protects data; the key
/// only lets the client reach the API as an anonymous/authenticated caller.
enum Config {
    static let supabaseURL = URL(string: "https://jlzgpcrrwkcutpqjntku.supabase.co")!
    static let supabaseAnonKey =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpsemdwY3Jyd2tjdXRwcWpudGt1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxMDQ5NjUsImV4cCI6MjA5MzY4MDk2NX0.Bw5a4pDuzTm2q6GmLheIXGvBiPwXZF6-dbnI3k8fCG8"
}