import SwiftUI

struct RegionsAdminView: View {
    let vm: AdminViewModel
    @State private var showAdd = false
    @State private var newName = ""

    var body: some View {
        List {
            if vm.regions.isEmpty {
                ContentUnavailableView("No regions", systemImage: "map",
                    description: Text("Create your first region to start assigning managers and teams."))
            } else {
                ForEach(vm.regions) { r in
                    Label(r.name, systemImage: "mappin.circle")
                }
            }
        }
        .navigationTitle("Regions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .task { await vm.loadRegions() }
        .alert("New Region", isPresented: $showAdd) {
            TextField("Region name", text: $newName)
            Button("Cancel", role: .cancel) { newName = "" }
            Button("Create") {
                let name = newName; newName = ""
                Task { await vm.createRegion(name: name) }
            }
        } message: {
            Text("e.g. West, Southwest, Midwest")
        }
    }
}
