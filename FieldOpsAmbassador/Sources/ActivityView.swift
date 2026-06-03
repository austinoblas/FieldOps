import SwiftUI
import Supabase
import Observation

@MainActor
@Observable
final class ActivityViewModel {
    var events: [FieldEvent] = []
    var isLoading = false

    private let client = Supa.shared.client

    func load(name: String?, id: UUID?) async {
        isLoading = true; defer { isLoading = false }
        do {
            let all: [FieldEvent] = try await client
                .from("events").select().execute().value
            events = all.filter { e in
                e.isCompleted && (e.ambassador == name || e.ambassadorId == id)
            }
        } catch {
            events = []
        }
    }

    var totalEvents: Int { events.count }
    var totalUnits: Int { events.compactMap(\.unitsSold).reduce(0, +) }
    var totalSamples: Int { events.compactMap(\.samples).reduce(0, +) }
    var avgLift: Double {
        let lifts = events.compactMap(\.salesLift)
        return lifts.isEmpty ? 0 : lifts.reduce(0, +) / Double(lifts.count)
    }
}

struct ActivityView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var vm = ActivityViewModel()

    private let cols = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: cols, spacing: 14) {
                    stat("Events", "\(vm.totalEvents)", "calendar")
                    stat("Units sold", "\(vm.totalUnits)", "cart.fill")
                    stat("Samples", "\(vm.totalSamples)", "gift.fill")
                    stat("Avg sales lift", String(format: "%.0f%%", vm.avgLift), "chart.line.uptrend.xyaxis")
                }
                .padding()
            }
            .navigationTitle("My Activity")
            .task { await vm.load(name: auth.profile?.name, id: auth.profile?.id) }
            .refreshable { await vm.load(name: auth.profile?.name, id: auth.profile?.id) }
        }
    }

    private func stat(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(Theme.brand)
            Text(value).font(.system(size: 30, weight: .bold, design: .rounded))
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
