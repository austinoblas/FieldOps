import SwiftUI

struct EventDetailView: View {
    let eventId: Int
    let vm: ScheduleViewModel

    @State private var location = LocationManager()
    @State private var showReport = false
    @State private var busy = false
    @State private var note: String?

    private var event: FieldEvent? { vm.events.first { $0.id == eventId } }

    var body: some View {
        Group {
            if let event {
                List {
                    detailsSection(event)
                    statusSection(event)
                    actionSection(event)
                }
            } else {
                ContentUnavailableView("Event unavailable", systemImage: "calendar.badge.exclamationmark")
            }
        }
        .navigationTitle(event?.name ?? "Event")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showReport) {
            if let event {
                ReportFormView(event: event, vm: vm)
            }
        }
        .overlay(alignment: .bottom) { banner }
    }

    // MARK: Sections

    @ViewBuilder
    private func detailsSection(_ e: FieldEvent) -> some View {
        Section("Details") {
            row("calendar", e.prettyDate)
            if let t = e.time { row("clock", t) }
            if let s = e.store { row("building.2", s) }
            if let a = e.storeAddress { row("mappin.and.ellipse", a) }
            if let p = e.product { row("shippingbox", p) }
        }
    }

    @ViewBuilder
    private func statusSection(_ e: FieldEvent) -> some View {
        Section("Status") {
            row("flag", e.statusLabel)
            if let ci = e.checkInAt { row("arrow.right.circle", "Checked in \(FieldEvent.prettyTime(ci))") }
            if let co = e.checkOutAt { row("arrow.left.circle", "Checked out \(FieldEvent.prettyTime(co))") }
            if e.isCompleted {
                if let u = e.unitsSold { row("cart", "\(u) units sold") }
                if let s = e.samples { row("gift", "\(s) samples") }
            }
        }
    }

    @ViewBuilder
    private func actionSection(_ e: FieldEvent) -> some View {
        Section {
            if e.needsConfirmation {
                Button {
                    run { await vm.accept(e) }
                } label: { Label("Accept event", systemImage: "checkmark.circle") }
                    .tint(Theme.brand)
                Button(role: .destructive) {
                    run { await vm.decline(e) }
                } label: { Label("Decline", systemImage: "xmark.circle") }
            } else if e.canCheckIn {
                Button {
                    run { await checkIn(e) }
                } label: { Label("Check in", systemImage: "mappin.and.ellipse") }
                    .tint(Theme.brand)
            } else if e.isCheckedIn {
                Button {
                    run { await checkOut(e) }
                } label: { Label("Check out", systemImage: "flag.checkered") }
                    .tint(Theme.brand)
            } else if e.canReport {
                Button {
                    showReport = true
                } label: { Label("Submit report", systemImage: "doc.badge.plus") }
                    .tint(Theme.brand)
            } else if e.isCompleted {
                Label("Report submitted", systemImage: "checkmark.seal")
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(busy)
    }

    private func row(_ icon: String, _ text: String) -> some View {
        Label(text, systemImage: icon)
            .labelStyle(.titleAndIcon)
    }

    @ViewBuilder
    private var banner: some View {
        if let note {
            Text(note)
                .font(.footnote).foregroundStyle(.white)
                .padding(10).background(Theme.brandDk, in: Capsule()).padding()
        }
    }

    // MARK: Actions

    private func run(_ work: @escaping () async -> Void) {
        busy = true
        Task { await work(); busy = false }
    }

    private func checkIn(_ e: FieldEvent) async {
        let coord = await location.fetch()
        if coord == nil && location.isDenied {
            note = "Location is off — checking in without it."
        } else if coord == nil {
            note = "Allow location, then tap Check in again."
            return
        }
        await vm.checkIn(e, lat: coord?.latitude, lng: coord?.longitude)
    }

    private func checkOut(_ e: FieldEvent) async {
        let coord = await location.fetch()
        await vm.checkOut(e, lat: coord?.latitude, lng: coord?.longitude)
    }
}
