import SwiftUI

struct ScheduleView: View {
    @State private var vm = ScheduleViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.events.isEmpty {
                    ProgressView("Loading your schedule…")
                } else if vm.events.isEmpty {
                    ContentUnavailableView(
                        "No events yet",
                        systemImage: "calendar",
                        description: Text("Your manager will assign events, or you can request one.")
                    )
                } else {
                    List {
                        section("Needs your confirmation", vm.needsConfirmation)
                        section("Pending approval", vm.pending)
                        section("Confirmed", vm.confirmed)
                        section("Past events", vm.past)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Schedule")
            .task { await vm.load() }
            .refreshable { await vm.load() }
            .overlay(alignment: .bottom) {
                if let err = vm.errorMessage {
                    Text(err).font(.footnote).foregroundStyle(.white)
                        .padding(10).background(Theme.brandDk, in: Capsule()).padding()
                }
            }
        }
    }

    @ViewBuilder
    private func section(_ title: String, _ items: [FieldEvent]) -> some View {
        if !items.isEmpty {
            Section(title) {
                ForEach(items) { event in
                    NavigationLink {
                        EventDetailView(eventId: event.id, vm: vm)
                    } label: {
                        EventRow(event: event)
                    }
                }
            }
        }
    }
}

struct EventRow: View {
    let event: FieldEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(event.name).font(.headline)
            HStack(spacing: 14) {
                label("calendar", event.prettyDate)
                if let t = event.time { label("clock", t) }
            }
            if let store = event.store { label("building.2", store) }
            Text(event.statusLabel)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(Theme.brand.opacity(0.15), in: Capsule())
                .foregroundStyle(Theme.brand)
        }
        .padding(.vertical, 4)
    }

    private func label(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(text).font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}
