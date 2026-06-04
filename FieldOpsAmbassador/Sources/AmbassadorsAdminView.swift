import SwiftUI

struct AmbassadorsAdminView: View {
    let vm: AdminViewModel
    let auth: AuthViewModel
    @State private var showInvite = false
    @State private var query = ""

    private var filtered: [Ambassador] {
        guard !query.isEmpty else { return vm.ambassadors }
        let q = query.lowercased()
        return vm.ambassadors.filter {
            $0.name.lowercased().contains(q) || ($0.email?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        List {
            if filtered.isEmpty {
                ContentUnavailableView("No ambassadors", systemImage: "person.2",
                    description: Text("Invite your first teammate by email."))
            } else {
                ForEach(filtered) { a in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(a.name).font(.headline)
                        HStack(spacing: 10) {
                            if let e = a.email { Text(e) }
                            if let r = a.rate { Text("$\(r, specifier: "%.0f")/hr") }
                            if auth.isAdmin { Text(vm.regionName(a.regionId)) }
                        }
                        .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Ambassadors")
        .searchable(text: $query, prompt: "Name or email")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showInvite = true } label: { Image(systemName: "plus") }
            }
        }
        .task { await vm.loadAmbassadors() }
        .sheet(isPresented: $showInvite) { InviteAmbassadorSheet(vm: vm, auth: auth) }
    }
}

private struct InviteAmbassadorSheet: View {
    let vm: AdminViewModel
    let auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var rate = ""
    @State private var regionId: Int?

    var body: some View {
        NavigationStack {
            Form {
                Section("Ambassador") {
                    TextField("Full name", text: $name)
                    TextField("Email", text: $email).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                    HStack {
                        Text("Rate $/hr"); Spacer()
                        TextField("0", text: $rate).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 80)
                    }
                }
                if auth.isAdmin {
                    Section("Region") {
                        Picker("Region", selection: $regionId) {
                            Text("Select…").tag(Int?.none)
                            ForEach(vm.regions) { r in Text(r.name).tag(Int?.some(r.id)) }
                        }
                    }
                } else {
                    Section { Text("Joins your region's team.").font(.caption).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("Invite Ambassador")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invite") {
                        let region = auth.isAdmin ? regionId : auth.myRegionId
                        Task {
                            await vm.inviteAmbassador(name: name, email: email, rate: Double(rate) ?? 0, regionId: region)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || email.isEmpty || vm.busy)
                }
            }
        }
    }
}
