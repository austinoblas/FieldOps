import SwiftUI

struct ManagersAdminView: View {
    let vm: AdminViewModel
    @State private var showInvite = false

    var body: some View {
        List {
            if vm.managers.isEmpty {
                ContentUnavailableView("No field managers", systemImage: "person.badge.shield.checkmark",
                    description: Text("Invite a manager to lead a region."))
            } else {
                ForEach(vm.managers) { m in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(m.name ?? m.email ?? "Manager").font(.headline)
                        HStack(spacing: 10) {
                            if let e = m.email { Text(e) }
                            Text(vm.regionName(m.regionId))
                        }
                        .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Field Managers")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showInvite = true } label: { Image(systemName: "plus") }
            }
        }
        .task { await vm.loadManagers(); if vm.regions.isEmpty { await vm.loadRegions() } }
        .sheet(isPresented: $showInvite) { InviteManagerSheet(vm: vm) }
    }
}

private struct InviteManagerSheet: View {
    let vm: AdminViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var regionId: Int?

    var body: some View {
        NavigationStack {
            Form {
                Section("Manager") {
                    TextField("Full name", text: $name)
                    TextField("Email", text: $email).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                }
                Section("Region") {
                    Picker("Region", selection: $regionId) {
                        Text("Select…").tag(Int?.none)
                        ForEach(vm.regions) { r in Text(r.name).tag(Int?.some(r.id)) }
                    }
                }
            }
            .navigationTitle("Invite Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invite") {
                        guard let region = regionId else { return }
                        Task {
                            await vm.inviteManager(name: name, email: email, regionId: region)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || email.isEmpty || regionId == nil || vm.busy)
                }
            }
        }
    }
}
