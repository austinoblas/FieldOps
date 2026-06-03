import SwiftUI

struct AmbassadorsAdminView: View {
    let vm: AdminViewModel
    @State private var showAdd = false

    var body: some View {
        List {
            if vm.ambassadors.isEmpty {
                ContentUnavailableView("No ambassadors", systemImage: "person.2",
                    description: Text("Add your first teammate."))
            } else {
                ForEach(vm.ambassadors) { a in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(a.name).font(.headline)
                        HStack(spacing: 10) {
                            if let c = a.city { Text(c) }
                            if let r = a.rate { Text("$\(r, specifier: "%.0f")/hr") }
                            if let s = a.status { Text(s.capitalized) }
                        }
                        .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Ambassadors")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .task { await vm.loadAmbassadors() }
        .sheet(isPresented: $showAdd) { AddAmbassadorSheet(vm: vm) }
    }
}

private struct AddAmbassadorSheet: View {
    let vm: AdminViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var city = ""
    @State private var specialty = ""
    @State private var rate = ""
    @State private var sendInvite = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Ambassador") {
                    TextField("Full name", text: $name)
                    TextField("Email", text: $email).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                    TextField("Phone", text: $phone).keyboardType(.phonePad)
                    TextField("City", text: $city)
                    TextField("Specialty", text: $specialty)
                    HStack {
                        Text("Rate $/hr"); Spacer()
                        TextField("0", text: $rate).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 80)
                    }
                }
                Section {
                    Toggle("Email login invite", isOn: $sendInvite)
                } footer: {
                    Text("Sends a TestFlight-style invite so they can set a password and log in. Requires the invite function deployed.")
                }
            }
            .navigationTitle("Add Ambassador")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await vm.addAmbassador(name: name, email: email, phone: phone,
                                rate: Double(rate) ?? 0, city: city, specialty: specialty, invite: sendInvite)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || vm.busy)
                }
            }
        }
    }
}
