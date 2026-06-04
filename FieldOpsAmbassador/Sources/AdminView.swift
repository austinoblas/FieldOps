import SwiftUI
import Supabase
import Observation

@MainActor
@Observable
final class AdminViewModel {
    var regions: [Region] = []
    var stores: [Store] = []
    var ambassadors: [Ambassador] = []
    var events: [FieldEvent] = []
    var payments: [Payment] = []
    var message: String?
    var busy = false

    private let client = Supa.shared.client

    func loadAll() async {
        await loadRegions()
        await loadStores()
        await loadAmbassadors()
    }

    func loadRegions() async {
        regions = (try? await client.from("regions").select().order("name").execute().value) ?? []
    }
    func loadStores() async {
        stores = (try? await client.from("stores").select().order("name").execute().value) ?? []
    }
    func loadAmbassadors() async {
        ambassadors = (try? await client.from("ambassadors").select().order("name").execute().value) ?? []
    }
    func loadEvents() async {
        events = (try? await client.from("events").select().order("date", ascending: false).execute().value) ?? []
    }
    func loadPayments() async {
        payments = (try? await client.from("payments").select().order("date", ascending: false).execute().value) ?? []
    }

    func setPaymentStatus(_ p: Payment, to status: String) async {
        struct Upd: Encodable { let status: String }
        await run {
            try await self.client.from("payments").update(Upd(status: status)).eq("id", value: p.id).execute()
            await self.loadPayments()
        }
    }

    /// Writes the given payments to a CSV in the temp dir and returns its URL for ShareLink.
    func payrollCSV(_ rows: [Payment]) -> URL? {
        func esc(_ s: String) -> String {
            (s.contains(",") || s.contains("\"")) ? "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\"" : s
        }
        func num(_ d: Double?) -> String { d.map { String(format: "%.2f", $0) } ?? "0" }
        var lines = ["Ambassador,Region,Event,Date,Hours,Rate,Expenses,Total,Status"]
        for p in rows {
            lines.append([
                esc(p.ambassador ?? ""), esc(regionName(p.regionId)), esc(p.eventName ?? ""),
                p.date ?? "", num(p.hours), num(p.rate), num(p.expenses), num(p.total), p.status ?? ""
            ].joined(separator: ","))
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("payroll.csv")
        do { try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8); return url }
        catch { return nil }
    }

    func regionName(_ id: Int?) -> String {
        guard let id else { return "—" }
        return regions.first { $0.id == id }?.name ?? "—"
    }

    // MARK: Mutations

    func createRegion(name: String) async {
        struct New: Encodable { let name: String }
        await run {
            try await self.client.from("regions").insert(New(name: name)).execute()
            await self.loadRegions()
            self.message = "Region \(name) created."
        }
    }

    func addStore(name: String, retailer: String, address: String, manager: String, phone: String, priority: String) async {
        struct New: Encodable { let name, retailer, address, manager, phone, priority: String }
        await run {
            try await self.client.from("stores")
                .insert(New(name: name, retailer: retailer, address: address, manager: manager, phone: phone, priority: priority))
                .execute()
            await self.loadStores()
        }
    }

    func addAmbassador(name: String, email: String, phone: String, rate: Double,
                       city: String, specialty: String, regionId: Int?, invite: Bool) async {
        struct New: Encodable { let name, email, phone, status, city, specialty: String; let rate: Double; let region_id: Int? }
        await run {
            try await self.client.from("ambassadors")
                .insert(New(name: name, email: email, phone: phone, status: "active",
                            city: city, specialty: specialty, rate: rate, region_id: regionId))
                .execute()
            if invite, !email.isEmpty {
                struct Body: Encodable { let email, name: String }
                try await self.client.functions.invoke("invite-ambassador", options: .init(body: Body(email: email, name: name)))
            }
            await self.loadAmbassadors()
            self.message = invite ? "Added and invited \(name)." : "Added \(name)."
        }
    }

    func createEvent(name: String, store: String, retailer: String, date: Date, time: String,
                     product: String, ambassador: String, regionId: Int?) async {
        struct New: Encodable {
            let name, store, retailer, date, time, product, ambassador, status: String; let region_id: Int?
        }
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        await run {
            try await self.client.from("events")
                .insert(New(name: name, store: store, retailer: retailer, date: df.string(from: date),
                            time: time, product: product, ambassador: ambassador, status: "upcoming", region_id: regionId))
                .execute()
            await self.loadEvents()
            self.message = "Event created for \(ambassador)."
        }
    }

    private func run(_ work: @escaping () async throws -> Void) async {
        busy = true; defer { busy = false }
        do { try await work() }
        catch { message = error.localizedDescription }
    }
}

struct AdminView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var vm = AdminViewModel()

    var body: some View {
        NavigationStack {
            List {
                if auth.isAdmin {
                    Section("HQ") {
                        NavigationLink { RegionsAdminView(vm: vm) } label: {
                            Label("Regions", systemImage: "map.fill")
                        }
                    }
                }
                Section(auth.isAdmin ? "All regions" : "Your region") {
                    NavigationLink { AmbassadorsAdminView(vm: vm, auth: auth) } label: {
                        Label("Ambassadors", systemImage: "person.2.fill")
                    }
                    NavigationLink { StoresAdminView(vm: vm) } label: {
                        Label("Retailers", systemImage: "storefront.fill")
                    }
                    NavigationLink { EventsAdminView(vm: vm, auth: auth) } label: {
                        Label("Events", systemImage: "calendar.badge.plus")
                    }
                    NavigationLink { PayrollAdminView(vm: vm) } label: {
                        Label("Payroll", systemImage: "dollarsign.square.fill")
                    }
                }
            }
            .navigationTitle("Admin")
            .task { await vm.loadAll() }
            .overlay(alignment: .bottom) {
                if let m = vm.message {
                    Text(m).font(.footnote).foregroundStyle(.white)
                        .padding(10).background(Theme.brandDk, in: Capsule()).padding()
                }
            }
        }
        .tint(Theme.brand)
    }
}
