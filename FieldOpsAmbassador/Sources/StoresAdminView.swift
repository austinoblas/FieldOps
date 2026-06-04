import SwiftUI

struct StoresAdminView: View {
    let vm: AdminViewModel
    @State private var showAdd = false

    var body: some View {
        List {
            if vm.stores.isEmpty {
                ContentUnavailableView("No retailers", systemImage: "storefront",
                    description: Text("Add the stores your team demos at."))
            } else {
                ForEach(vm.stores) { s in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.name).font(.headline)
                            HStack(spacing: 10) {
                                if let r = s.retailer { Text(r) }
                                if let a = s.address { Text(a) }
                            }
                            .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let phone = s.phone, let url = telURL(phone) {
                            Link(destination: url) {
                                Image(systemName: "phone.fill").foregroundStyle(Theme.brand)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }
        }
        .navigationTitle("Retailers")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .task { await vm.loadStores() }
        .sheet(isPresented: $showAdd) { AddStoreSheet(vm: vm) }
    }

    private func telURL(_ phone: String) -> URL? {
        let digits = phone.filter(\.isNumber)
        return digits.isEmpty ? nil : URL(string: "tel:\(digits)")
    }
}

private struct AddStoreSheet: View {
    let vm: AdminViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var retailer = ""
    @State private var address = ""
    @State private var manager = ""
    @State private var phone = ""
    @State private var priority = "medium"

    var body: some View {
        NavigationStack {
            Form {
                Section("Store") {
                    TextField("Store name", text: $name)
                    TextField("Retailer (e.g. Sprouts)", text: $retailer)
                    TextField("Address", text: $address)
                }
                Section("Contact") {
                    TextField("Store manager", text: $manager)
                    TextField("Phone", text: $phone).keyboardType(.phonePad)
                    Picker("Priority", selection: $priority) {
                        Text("High").tag("high")
                        Text("Medium").tag("medium")
                        Text("Low").tag("low")
                    }
                }
            }
            .navigationTitle("Add Retailer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await vm.addStore(name: name, retailer: retailer, address: address,
                                manager: manager, phone: phone, priority: priority)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || vm.busy)
                }
            }
        }
    }
}
