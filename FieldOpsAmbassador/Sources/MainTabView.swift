import SwiftUI

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var auth

    var body: some View {
        TabView {
            ScheduleView()
                .tabItem { Label("Schedule", systemImage: "calendar") }
            ActivityView()
                .tabItem { Label("Activity", systemImage: "chart.bar.fill") }
            PayView()
                .tabItem { Label("Pay", systemImage: "dollarsign.circle.fill") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
            if auth.canAdmin {
                AdminView()
                    .tabItem { Label("Admin", systemImage: "slider.horizontal.3") }
            }
        }
        .tint(Theme.brand)
    }
}
