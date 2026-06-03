import Foundation

/// Mirrors a row in `profiles`.
struct Profile: Codable, Identifiable, Sendable {
    let id: UUID
    var name: String?
    var email: String?
    var phone: String?
    var role: String?

    var isManager: Bool { role == "manager" }
}

/// Mirrors a row in `events`. Only the fields the ambassador app needs are
/// modeled; everything is optional except id/name so partial rows still decode.
/// The Postgres `date` column comes back as an ISO date string ("2026-05-10"),
/// which we keep as a String and format for display.
struct FieldEvent: Codable, Identifiable, Sendable {
    let id: Int
    var name: String
    var store: String?
    var storeAddress: String?
    var date: String?
    var time: String?
    var status: String?
    var product: String?
    var hourlyRate: Double?
    var ambassador: String?
    var accepted: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, store
        case storeAddress = "store_address"
        case date, time, status, product
        case hourlyRate = "hourly_rate"
        case ambassador, accepted
    }

    // MARK: Display helpers
    var isPending: Bool   { status == "pending_approval" }
    var isUpcoming: Bool  { status == "upcoming" }
    var isCompleted: Bool { status == "completed" }
    var needsConfirmation: Bool { isUpcoming && (accepted ?? false) == false }

    var prettyDate: String {
        guard let date else { return "—" }
        let inFmt = DateFormatter(); inFmt.dateFormat = "yyyy-MM-dd"
        guard let d = inFmt.date(from: date) else { return date }
        let outFmt = DateFormatter(); outFmt.dateFormat = "EEE, MMM d"
        return outFmt.string(from: d)
    }
}