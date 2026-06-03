import SwiftUI

struct ScheduleView: View {
    @Environment(AuthViewModel.self) private var auth
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await auth.signOut() } } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
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
                    EventRow(event: event) {
                        await vm.accept(event)
                    } onDecline: {
                        await vm.decline(event)
                    }
                }
            }
        }
    }
}

struct EventRow: View {
    let event: FieldEvent
    let onAccept: () async -> Void
    let onDecline: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.name).font(.headline)

            HStack(spacing: 14) {
                label("calendar", event.prettyDate)
                if let t = event.time { label("clock", t) }
            }
            if let store = event.store { label("building.2", store) }
            if let p = event.product { label("shippingbox", p) }

            // Actions depend on event state
            if event.needsConfirmation {
                HStack {
                    Button("Accept") { Task { await onAccept() } }
                        .buttonStyle(.borderedProminent).tint(Theme.brand)
                    Button("Decline", role: .destructive) { Task { await onDecline() } }
                        .buttonStyle(.bordered)
                }
                .padding(.top, 4)
            } else if event.isCompleted {
                // Phase 4 hooks — wired up next session
                HStack {
                    Button { } label: { Label("Check in", systemImage: "mappin.and.ellipse") }
                        .buttonStyle(.bordered).disabled(true)
                    Button { } label: { Label("Submit report", systemImage: "doc.badge.plus") }
                        .buttonStyle(.borderedProminent).tint(Theme.brand).disabled(true)
                }
                .padding(.top, 4)
                Text("Check-in & reporting arrive in the next build.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
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