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

private enum Recurrence: String, CaseIterable, Identifiable {
    case none = "One-time", weekly = "Weekly", biweekly = "Every 2 wks"
    var id: String { rawValue }
    var step: Int { self == .weekly ? 7 : self == .biweekly ? 14 : 0 }
}

private struct AddEventSheet: View {
    let vm: AdminViewModel
    let auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var storeName = ""
    @State private var ambassador = ""
    @State private var product = ""
    @State private var date = Date()
    @State private var start = Self.defaultStart
    @State private var end = Self.defaultEnd
    @State private var recurrence = Recurrence.none
    @State private var occurrences = 4
    @State private var regionId: Int?

    private static var defaultStart: Date { Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date() }
    private static var defaultEnd: Date { Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date() }

    private var selectedStore: Store? { vm.stores.first { $0.name == storeName } }

    private var dates: [Date] {
        let count = recurrence == .none ? 1 : occurrences
        return (0..<count).compactMap { Calendar.current.date(byAdding: .day, value: $0 * recurrence.step, to: date) }
    }

    private var timeString: String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"
        return "\(f.string(from: start)) – \(f.string(from: end))"
    }

    private var conflictCount: Int {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let mine = Set(vm.events.filter { $0.ambassador == ambassador }.compactMap(\.date))
        return dates.map { df.string(from: $0) }.filter { mine.contains($0) }.count
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    TextField("Event name", text: $name)
                    TextField("Product", text: $product)
                }
                Section("Store") {
                    Picker("Retailer", selection: $storeName) {
                        Text("Select…").tag("")
                        ForEach(vm.stores) { s in Text(s.name).tag(s.name) }
                    }
                }
                Section("When") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    DatePicker("Start", selection: $start, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $end, displayedComponents: .hourAndMinute)
                    Picker("Repeat", selection: $recurrence) {
                        ForEach(Recurrence.allCases) { Text($0.rawValue).tag($0) }
                    }
                    if recurrence != .none {
                        Stepper("\(occurrences) demos", value: $occurrences, in: 2...12)
                    }
                }
                Section("Assign to") {
                    Picker("Ambassador", selection: $ambassador) {
                        Text("Select…").tag("")
                        ForEach(vm.ambassadors) { a in Text(a.name).tag(a.name) }
                    }
                    if conflictCount > 0 {
                        Label("\(ambassador) is already booked on \(conflictCount) of these date\(conflictCount == 1 ? "" : "s")",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.caption).foregroundStyle(Theme.gold)
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
                    Button(dates.count > 1 ? "Create \(dates.count)" : "Create") {
                        let region = auth.isAdmin ? regionId : auth.myRegionId
                        Task {
                            await vm.createEvents(name: name, store: storeName,
                                retailer: selectedStore?.retailer ?? "", dates: dates, time: timeString,
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
