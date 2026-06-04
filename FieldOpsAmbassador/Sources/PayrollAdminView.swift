import SwiftUI

struct PayrollAdminView: View {
    let vm: AdminViewModel
    @State private var statusFilter = "pending"
    @State private var exportURL: URL?

    private var filtered: [Payment] {
        statusFilter == "all" ? vm.payments : vm.payments.filter { $0.status == statusFilter }
    }
    private var total: Double { filtered.compactMap(\.total).reduce(0, +) }
    private var hours: Double { filtered.compactMap(\.hours).reduce(0, +) }

    var body: some View {
        List {
            Section {
                Picker("Status", selection: $statusFilter) {
                    Text("Pending").tag("pending")
                    Text("Approved").tag("approved")
                    Text("Paid").tag("paid")
                    Text("All").tag("all")
                }
                .pickerStyle(.segmented)
                LabeledContent("Owed", value: total, format: .currency(code: "USD"))
                LabeledContent("Hours", value: String(format: "%.1f", hours))
            }

            if filtered.isEmpty {
                ContentUnavailableView("Nothing here", systemImage: "dollarsign.circle",
                    description: Text("Payroll is generated automatically when ambassadors submit reports."))
            } else {
                Section("\(filtered.count) line items") {
                    ForEach(filtered) { p in row(p) }
                }
            }
        }
        .navigationTitle("Payroll")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let exportURL {
                    ShareLink(item: exportURL) { Image(systemName: "square.and.arrow.up") }
                }
            }
        }
        .task { await vm.loadPayments(); refresh() }
        .refreshable { await vm.loadPayments(); refresh() }
        .onChange(of: statusFilter) { refresh() }
    }

    private func refresh() { exportURL = vm.payrollCSV(filtered) }

    private func row(_ p: Payment) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(p.ambassador ?? "—").font(.headline)
                Spacer()
                Text((p.total ?? 0), format: .currency(code: "USD")).bold()
            }
            HStack(spacing: 10) {
                Text(p.eventName ?? "").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                if let h = p.hours { Text("\(h, specifier: "%.1f")h").font(.caption2).foregroundStyle(.secondary) }
                Text((p.status ?? "pending").capitalized)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(badge(p.status), in: Capsule())
            }
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .trailing) {
            if p.status == "pending" {
                Button("Approve") { Task { await vm.setPaymentStatus(p, to: "approved"); refresh() } }
                    .tint(Theme.gold)
            }
            if p.status != "paid" {
                Button("Mark paid") { Task { await vm.setPaymentStatus(p, to: "paid"); refresh() } }
                    .tint(.green)
            }
        }
    }

    private func badge(_ status: String?) -> Color {
        switch status {
        case "paid": return .green.opacity(0.22)
        case "approved": return Theme.gold.opacity(0.25)
        default: return Theme.brand.opacity(0.15)
        }
    }
}
