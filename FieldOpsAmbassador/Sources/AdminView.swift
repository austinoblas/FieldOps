import SwiftUI

struct AdminView: View {
    @Environment(AuthViewModel.self) private var auth

    var body: some View {
        NavigationStack {
            List {
                Section("Manager tools") {
                    adminRow("person.badge.plus", "Add ambassadors", "Invite teammates by email")
                    adminRow("storefront", "Retailers", "Manage store directory")
                    adminRow("calendar.badge.plus", "Create events", "Assign demos to your team")
                }
                Section {
                    Text("Coming in the next build. You can already run your own demos from the Schedule tab.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Admin")
        }
    }

    private func adminRow(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        Label {
            VStack(alignment: .leading) {
                Text(title)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon).foregroundStyle(Theme.brand)
        }
        .opacity(0.5)
    }
}
