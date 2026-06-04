import SwiftUI
import Supabase
import Observation

enum DashPeriod: String, CaseIterable, Identifiable {
    case week = "7 days", month = "30 days", all = "All time"
    var id: String { rawValue }
    var days: Int? { self == .week ? 7 : self == .month ? 30 : nil }
}

@MainActor
@Observable
final class DashboardViewModel {
    var events: [FieldEvent] = []
    var payments: [Payment] = []
    var regions: [Region] = []
    var period: DashPeriod = .month
    var isLoading = false

    private let client = Supa.shared.client

    func load() async {
        isLoading = true; defer { isLoading = false }
        events = (try? await client.from("events").select().execute().value) ?? []
        payments = (try? await client.from("payments").select().execute().value) ?? []
        regions = (try? await client.from("regions").select().execute().value) ?? []
    }

    private var cutoff: String? {
        guard let days = period.days, let d = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else { return nil }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }

    private func inPeriod(_ date: String?) -> Bool {
        guard let cutoff else { return true }
        guard let date else { return false }
        return date >= cutoff
    }

    var completed: [FieldEvent] { events.filter { $0.isCompleted && inPeriod($0.date) } }
    var liveNow: [FieldEvent] { events.filter { $0.isCheckedIn } }

    var totalEvents: Int { completed.count }
    var totalUnits: Int { completed.compactMap(\.unitsSold).reduce(0, +) }
    var totalSamples: Int { completed.compactMap(\.samples).reduce(0, +) }
    var avgLift: Double {
        let l = completed.compactMap(\.salesLift); return l.isEmpty ? 0 : l.reduce(0, +) / Double(l.count)
    }
    var payrollTotal: Double { payments.filter { inPeriod($0.date) }.compactMap(\.total).reduce(0, +) }

    func regionName(_ id: Int?) -> String {
        guard let id else { return "Unassigned" }
        return regions.first { $0.id == id }?.name ?? "Region \(id)"
    }

    var byRegion: [(String, Int)] {
        let groups = Dictionary(grouping: completed) { regionName($0.regionId) }
        var totals: [(String, Int)] = groups.map { name, evs in
            (name, evs.compactMap(\.unitsSold).reduce(0, +))
        }
        totals.sort { $0.1 > $1.1 }
        return totals
    }
    var topRetailers: [(String, Int)] { top { $0.retailer ?? $0.store } }
    var topProducts: [(String, Int)]  { top { $0.product } }

    private func top(by key: (FieldEvent) -> String?) -> [(String, Int)] {
        let matching = completed.filter { key($0) != nil }
        let groups = Dictionary(grouping: matching) { key($0) ?? "—" }
        var totals: [(String, Int)] = groups.map { name, evs in
            (name, evs.compactMap(\.unitsSold).reduce(0, +))
        }
        totals.sort { $0.1 > $1.1 }
        return Array(totals.prefix(5))
    }
}

struct DashboardView: View {
    let auth: AuthViewModel
    @State private var vm = DashboardViewModel()

    private let cols = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Picker("Period", selection: $vm.period) {
                    ForEach(DashPeriod.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                LazyVGrid(columns: cols, spacing: 12) {
                    stat("Demos", "\(vm.totalEvents)", "calendar")
                    stat("Units sold", "\(vm.totalUnits)", "cart.fill")
                    stat("Samples", "\(vm.totalSamples)", "gift.fill")
                    stat("Avg lift", String(format: "%.0f%%", vm.avgLift), "chart.line.uptrend.xyaxis")
                    stat("Payroll", vm.payrollTotal.formatted(.currency(code: "USD").precision(.fractionLength(0))), "dollarsign.circle.fill")
                }

                if !vm.liveNow.isEmpty { liveSection }

                if auth.isAdmin && !vm.byRegion.isEmpty {
                    breakdown("Units by region", vm.byRegion)
                }
                if !vm.topRetailers.isEmpty { breakdown("Top retailers", vm.topRetailers) }
                if !vm.topProducts.isEmpty { breakdown("Top products", vm.topProducts) }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .task { await vm.load() }
        .refreshable { await vm.load() }
        .overlay {
            if vm.isLoading && vm.events.isEmpty { ProgressView() }
        }
    }

    private func stat(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundStyle(Theme.brand)
            Text(value).font(.system(size: 26, weight: .bold, design: .rounded)).minimumScaleFactor(0.6).lineLimit(1)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var liveSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(.green).frame(width: 8, height: 8)
                Text("Live now").font(.headline)
                Text("\(vm.liveNow.count)").font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(vm.liveNow) { e in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(e.ambassador ?? "—").font(.subheadline.weight(.semibold))
                        if let s = e.store { Text(s).font(.caption).foregroundStyle(.secondary) }
                    }
                    Spacer()
                    if let ci = e.checkInAt {
                        Text("in \(FieldEvent.prettyTime(ci))").font(.caption).foregroundStyle(.green)
                    }
                }
                Divider()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func breakdown(_ title: String, _ rows: [(String, Int)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            ForEach(rows, id: \.0) { name, value in
                HStack {
                    Text(name).lineLimit(1)
                    Spacer()
                    Text("\(value)").bold().foregroundStyle(Theme.brand)
                }
                .font(.subheadline)
                Divider()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
