import SwiftUI

@main
struct FieldOpsAmbassadorApp: App {
    @State private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .tint(Theme.brand)
                .task { await auth.bootstrap() }
        }
    }
}

struct RootView: View {
    @Environment(AuthViewModel.self) private var auth

    var body: some View {
        switch auth.phase {
        case .loading:
            ProgressView("Loading…")
        case .signedOut:
            LoginView()
        case .signedIn:
            ScheduleView()
        }
    }
}