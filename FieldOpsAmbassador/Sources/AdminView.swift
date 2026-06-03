import SwiftUI
import Supabase
import Observation

@MainActor
@Observable
final class AdminViewModel {
    var stores: [Store] = []
    var ambassadors: [Ambassador] = []
    var events: [FieldEvent] = []
    var message: String?
    var busy = false

    private let client = Supa.shared.client

    func loadAll() async {
        await loadStores()
        await loadAmbassadors()
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

    // MARK: Mutations

    func addStore(name: String, retailer: String, address: String, manager: String, phone: String, priority: String) async {
        struct New: Encodable { let name, retailer, address, manager, phone, priority: String }
        await run {
            try await self.client.from("stores")
                .insert(New(name: name, retailer: retailer, address: address, manager: manager, phone: phone, priority: priority))
                .execute()
            await self.loadStores()
        }
    }

    func addAmbassador(name: String, email: String, phone: String, rate: Double, city: String, specialty: String, invite: Bool) async {
        struct New: Encodable { let name, email, phone, status, city, specialty: String; let rate: Double }
        await run {
            try await self.client.from("ambassadors")
                .insert(New(name: name, email: email, phone: phone, status: "active", city: city, specialty: specialty, rate: rate))
                .execute()
            if invite, !email.isEmpty {
                struct Body: Encodable { let email, name: String }
                try await self.client.functions.invoke("invite-ambassador", options: .init(body: Body(email: email, name: name)))
            }
            await self.loadAmbassadors()
            self.message = invite ? "Added and invited \(name)." : "Added \(name)."
        }
    }

    func createEvent(name: String, store: String, retailer: String, date: Date, time: String, product: String, ambassador: String) async {
        struct New: Encodable { let name, store, retailer, date, time, product, ambassador, status: String }
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        await run {
            try await self.client.from("events")
                .insert(New(name: name, store: store, retailer: retailer, date: df.string(from: date),
                            time: time, product: product, ambassador: ambassador, status: "upcoming"))
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
    @State private var vm = AdminViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("Manage your team") {
                    NavigationLink { AmbassadorsAdminView(vm: vm) } label: {
                        Label("Ambassadors", systemImage: "person.2.fill")
                    }
                    NavigationLink { StoresAdminView(vm: vm) } label: {
                        Label("Retailers", systemImage: "storefront.fill")
                    }
                    NavigationLink { EventsAdminView(vm: vm) } label: {
                        Label("Events", systemImage: "calendar.badge.plus")
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
