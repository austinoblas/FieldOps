import SwiftUI
import Supabase
import Observation

@MainActor
@Observable
final class PaymentsViewModel {
    var payments: [Payment] = []
    var isLoading = false

    private let client = Supa.shared.client

    func load(name: String?) async {
        guard let name else { return }
        isLoading = true; defer { isLoading = false }
        do {
            payments = try await client
                .from("payments").select()
                .eq("ambassador", value: name)
                .order("date", ascending: false)
                .execute().value
        } catch {
            payments = []
        }
    }

    var paidTotal: Double { payments.filter { $0.status == "paid" }.compactMap(\.total).reduce(0, +) }
    var pendingTotal: Double { payments.filter { $0.status != "paid" }.compactMap(\.total).reduce(0, +) }
}

struct PayView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var vm = PaymentsViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        summary("Paid", vm.paidTotal)
                        Divider()
                        summary("Pending", vm.pendingTotal)
                    }
                }
                if vm.payments.isEmpty {
                    ContentUnavailableView("No payments yet", systemImage: "dollarsign.circle",
                        description: Text("Payments appear after you submit event reports."))
                } else {
                    Section("History") {
                        ForEach(vm.payments) { p in row(p) }
                    }
                }
            }
            .navigationTitle("My Pay")
            .task { await vm.load(name: auth.profile?.name) }
            .refreshable { await vm.load(name: auth.profile?.name) }
        }
    }

    private func summary(_ label: String, _ amount: Double) -> some View {
        VStack {
            Text(amount, format: .currency(code: "USD")).font(.title3.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ p: Payment) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(p.eventName ?? "Event").font(.headline)
                Spacer()
                Text((p.total ?? 0), format: .currency(code: "USD")).font(.headline)
            }
            HStack(spacing: 12) {
                if let h = p.hours { Text("\(h, specifier: "%.1f") hrs").font(.caption).foregroundStyle(.secondary) }
                Text((p.status ?? "pending").capitalized)
                    .font(.caption2).padding(.horizontal, 8).padding(.vertical, 2)
                    .background(p.status == "paid" ? Color.green.opacity(0.2) : Theme.gold.opacity(0.25), in: Capsule())
            }
        }
        .padding(.vertical, 2)
    }
}
