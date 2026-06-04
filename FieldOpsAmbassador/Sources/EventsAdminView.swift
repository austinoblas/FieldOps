import SwiftUI

struct EventsAdminView: View {
    let vm: AdminViewModel
    let auth: AuthViewModel
    @State private var showAdd = false

    var body: some View {
        List {
            if vm.events.isEmpty {
                ContentUnavailableView("No events", systemImage: "calendar",
                    description: Text("Create and assign a demo to your team."))
            } else {
                ForEach(vm.events) { e in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(e.name).font(.headline)
                        HStack(spacing: 10) {
                            Text(e.prettyDate)
                            if let a = e.ambassador { Text(a) }
                            if auth.isAdmin { Text(vm.regionName(e.regionId)) }
                            Text(e.statusLabel)
                        }
                        .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Events")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .task {
            await vm.loadEvents()
            if vm.stores.isEmpty { await vm.loadStores() }
            if vm.ambassadors.isEmpty { await vm.loadAmbassadors() }
        }
        .sheet(isPresented: $showAdd) { AddEventSheet(vm: vm, auth: auth) }
    }
}

private struct AddEventSheet: View {
    let vm: AdminViewModel
    let auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var storeName = ""
    @State private var ambassador = ""
    @State private var product = ""
    @State private var time = ""
    @State private var date = Date()
    @State private var regionId: Int?

    private var selectedStore: Store? { vm.stores.first { $0.name == storeName } }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    TextField("Event name", text: $name)
                    TextField("Product", text: $product)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Time (e.g. 12:00 – 4:00 PM)", text: $time)
                }
                Section("Store") {
                    Picker("Retailer", selection: $storeName) {
                        Text("Select…").tag("")
                        ForEach(vm.stores) { s in Text(s.name).tag(s.name) }
                    }
                }
                Section("Assign to") {
                    Picker("Ambassador", selection: $ambassador) {
                        Text("Select…").tag("")
                        ForEach(vm.ambassadors) { a in Text(a.name).tag(a.name) }
                    }
                }
                if auth.isAdmin {
                    Section("Region") {
                        Picker("Region", selection: $regionId) {
                            Text("Select…").tag(Int?.none)
                            ForEach(vm.regions) { r in Text(r.name).tag(Int?.some(r.id)) }
                        }
                    }
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let region = auth.isAdmin ? regionId : auth.myRegionId
                        Task {
                            await vm.createEvent(name: name, store: storeName,
                                retailer: selectedStore?.retailer ?? "", date: date, time: time,
                                product: product, ambassador: ambassador, regionId: region)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || storeName.isEmpty || ambassador.isEmpty || vm.busy)
                }
            }
        }
    }
}
