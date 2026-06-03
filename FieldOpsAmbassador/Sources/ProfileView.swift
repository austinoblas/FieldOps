import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var auth

    @State private var name = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var shirtSize = ""
    @State private var saved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Email", value: auth.profile?.email ?? "—")
                    LabeledContent("Role", value: (auth.profile?.role ?? "ambassador").capitalized)
                }
                Section("Your details") {
                    labeled("Name", $name)
                    labeled("Phone", $phone)
                    labeled("Address", $address)
                    labeled("Shirt size", $shirtSize)
                }
                Section {
                    Button {
                        Task {
                            await auth.updateProfile(name: name, phone: phone, address: address, shirtSize: shirtSize)
                            saved = true
                        }
                    } label: {
                        Text(auth.busy ? "Saving…" : "Save changes").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(Theme.brand)
                    .disabled(auth.busy)
                }
                Section {
                    Button(role: .destructive) {
                        Task { await auth.signOut() }
                    } label: {
                        Text("Sign out").frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear(perform: hydrate)
            .alert("Saved", isPresented: $saved) { Button("OK", role: .cancel) {} }
        }
    }

    private func labeled(_ title: String, _ binding: Binding<String>) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            TextField(title, text: binding).multilineTextAlignment(.trailing)
        }
    }

    private func hydrate() {
        guard let p = auth.profile else { return }
        name = p.name ?? ""
        phone = p.phone ?? ""
        address = p.address ?? ""
        shirtSize = p.shirtSize ?? ""
    }
}
