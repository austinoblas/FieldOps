import Foundation

/// Mirrors a row in `regions`.
struct Region: Codable, Identifiable, Sendable {
    let id: Int
    var name: String
    var managerId: UUID?

    enum CodingKeys: String, CodingKey {
        case id, name
        case managerId = "manager_id"
    }
}

/// Mirrors a row in `profiles`.
struct Profile: Codable, Identifiable, Sendable {
    let id: UUID
    var name: String?
    var email: String?
    var phone: String?
    var address: String?
    var shirtSize: String?
    var role: String?
    var regionId: Int?
    var managerId: UUID?

    var isManager: Bool { role == "manager" }
    var isAdmin: Bool { role == "admin" }

    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, address, role
        case shirtSize = "shirt_size"
        case regionId = "region_id"
        case managerId = "manager_id"
    }
}

/// Mirrors a row in `payments`.
struct Payment: Codable, Identifiable, Sendable {
    let id: Int
    var ambassador: String?
    var eventName: String?
    var date: String?
    var hours: Double?
    var rate: Double?
    var expenses: Double?
    var total: Double?
    var status: String?
    var regionId: Int?

    enum CodingKeys: String, CodingKey {
        case id, ambassador, date, hours, rate, expenses, total, status
        case eventName = "event_name"
        case regionId = "region_id"
    }
}

/// Mirrors a row in `stores` (retailer directory).
struct Store: Codable, Identifiable, Sendable {
    let id: Int
    var name: String
    var retailer: String?
    var address: String?
    var manager: String?
    var phone: String?
    var priority: String?
    var lat: Double?
    var lng: Double?
}

/// Mirrors a row in `ambassadors` (roster / rates).
struct Ambassador: Codable, Identifiable, Sendable {
    let id: Int
    var name: String
    var email: String?
    var phone: String?
    var status: String?
    var rate: Double?
    var city: String?
    var specialty: String?
    var regionId: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, status, rate, city, specialty
        case regionId = "region_id"
    }
}

/// Mirrors a row in `events`. The Postgres `date` column comes back as an ISO
/// date string ("2026-05-10"); check-in/out are ISO timestamps.
struct FieldEvent: Codable, Identifiable, Sendable {
    let id: Int
    var name: String
    var store: String?
    var storeAddress: String?
    var retailer: String?
    var date: String?
    var time: String?
    var status: String?
    var product: String?
    var hourlyRate: Double?
    var ambassador: String?
    var ambassadorId: UUID?
    var regionId: Int?
    var accepted: Bool?
    var unitsSold: Int?
    var samples: Int?
    var salesLift: Double?
    var checkInAt: String?
    var checkOutAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, store
        case storeAddress = "store_address"
        case retailer
        case date, time, status, product
        case hourlyRate = "hourly_rate"
        case ambassador
        case ambassadorId = "ambassador_id"
        case regionId = "region_id"
        case accepted
        case unitsSold = "units_sold"
        case samples
        case salesLift = "sales_lift"
        case checkInAt = "check_in_at"
        case checkOutAt = "check_out_at"
    }

    // MARK: State
    var isPending: Bool   { status == "pending_approval" }
    var isUpcoming: Bool  { status == "upcoming" }
    var isCompleted: Bool { status == "completed" }

    var needsConfirmation: Bool { isUpcoming && (accepted ?? false) == false }
    var canCheckIn: Bool  { isUpcoming && (accepted ?? false) && checkInAt == nil }
    var isCheckedIn: Bool { checkInAt != nil && checkOutAt == nil }
    var canReport: Bool   { checkOutAt != nil && !isCompleted }

    var isToday: Bool {
        guard let date else { return false }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return date == f.string(from: Date())
    }

    var statusLabel: String {
        if isCompleted { return "Completed" }
        if canReport { return "Awaiting report" }
        if isCheckedIn { return "Checked in" }
        if isPending { return "Pending approval" }
        if needsConfirmation { return "Needs confirmation" }
        return "Confirmed"
    }

    // MARK: Display helpers
    var prettyDate: String {
        guard let date else { return "—" }
        let inFmt = DateFormatter(); inFmt.dateFormat = "yyyy-MM-dd"
        guard let d = inFmt.date(from: date) else { return date }
        let outFmt = DateFormatter(); outFmt.dateFormat = "EEE, MMM d"
        return outFmt.string(from: d)
    }

    static func prettyTime(_ iso: String) -> String {
        let cleaned = iso.replacingOccurrences(of: #"\.\d+"#, with: "", options: .regularExpression)
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime]
        guard let d = f.date(from: cleaned) else { return "" }
        let out = DateFormatter(); out.dateFormat = "h:mm a"
        return out.string(from: d)
    }
}
