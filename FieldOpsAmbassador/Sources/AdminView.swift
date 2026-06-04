import SwiftUI
import Supabase
import Observation

@MainActor
@Observable
final class AdminViewModel {
    var regions: [Region] = []
    var stores: [Store] = []
    var ambassadors: [Ambassador] = []
    var managers: [Profile] = []
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
        struct New: Encodable { let name, retailer, address, manager, phone, priority: String; let lat, lng: Double? }
        await run {
            let coord = await Geocoder.coordinates(for: address)
            try await self.client.from("stores")
                .insert(New(name: name, retailer: retailer, address: address, manager: manager, phone: phone,
                            priority: priority, lat: coord?.latitude, lng: coord?.longitude))
                .execute()
            await self.loadStores()
            self.message = coord == nil ? "Added \(name) (address not located — no geofence)." : "Added \(name)."
        }
    }

    func loadManagers() async {
        managers = (try? await client.from("profiles").select()
            .eq("role", value: "manager").order("name").execute().value) ?? []
    }

    /// Manager invites an ambassador to their region (admin may target a region).
    /// Creation happens server-side in the Edge Function, so no RLS issue.
    func inviteAmbassador(name: String, email: String, rate: Double, regionId: Int?) async {
        struct Body: Encodable { let email, name: String; let rate: Double; let region_id: Int? }
        await run {
            try await self.client.functions.invoke("invite-ambassador",
                options: .init(body: Body(email: email, name: name, rate: rate, region_id: regionId)))
            await self.loadAmbassadors()
            self.message = "Invited \(name)."
        }
    }

    /// HQ admin invites a regional field manager.
    func inviteManager(name: String, email: String, regionId: Int) async {
        struct Body: Encodable { let email, name: String; let region_id: Int }
        await run {
            try await self.client.functions.invoke("invite-manager",
                options: .init(body: Body(email: email, name: name, region_id: regionId)))
            await self.loadManagers()
            self.message = "Invited \(name) as manager."
        }
    }

    func createEvents(name: String, store: String, retailer: String, dates: [Date], time: String,
                      product: String, ambassador: String, regionId: Int?, storeLat: Double?, storeLng: Double?) async {
        struct New: Encodable {
            let name, store, retailer, date, time, product, ambassador, status: String
            let region_id: Int?; let store_lat, store_lng: Double?
        }
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let rows = dates.map {
            New(name: name, store: store, retailer: retailer, date: df.string(from: $0),
                time: time, product: product, ambassador: ambassador, status: "upcoming",
                region_id: regionId, store_lat: storeLat, store_lng: storeLng)
        }
        await run {
            try await self.client.from("events").insert(rows).execute()
            await self.loadEvents()
            self.message = rows.count > 1 ? "Created \(rows.count) demos for \(ambassador)." : "Event created for \(ambassador)."
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
                Section {
                    NavigationLink { DashboardView(auth: auth) } label: {
                        Label("Dashboard", systemImage: "chart.bar.xaxis")
                    }
                }
                if auth.isAdmin {
                    Section("HQ") {
                        NavigationLink { RegionsAdminView(vm: vm) } label: {
                            Label("Regions", systemImage: "map.fill")
                        }
                        NavigationLink { ManagersAdminView(vm: vm) } label: {
                            Label("Field Managers", systemImage: "person.badge.shield.checkmark")
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
