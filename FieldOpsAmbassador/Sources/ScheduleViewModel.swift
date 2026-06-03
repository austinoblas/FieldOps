import Foundation
import Supabase
import Observation

@MainActor
@Observable
final class ScheduleViewModel {
    var events: [FieldEvent] = []
    var isLoading = false
    var errorMessage: String?

    private let client = Supa.shared.client

    // RLS already scopes `events` to the signed-in ambassador, so a plain
    // select returns only their own rows.
    func load() async {
        isLoading = true; defer { isLoading = false }
        errorMessage = nil
        do {
            events = try await client
                .from("events")
                .select()
                .order("date", ascending: true)
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func accept(_ event: FieldEvent) async { await callRPC("accept_event", id: event.id) }
    func decline(_ event: FieldEvent) async { await callRPC("decline_event", id: event.id) }

    private func callRPC(_ fn: String, id: Int) async {
        do {
            try await client.rpc(fn, params: ["p_event_id": id]).execute()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Grouped for display
    var needsConfirmation: [FieldEvent] { events.filter { $0.needsConfirmation } }
    var pending: [FieldEvent]  { events.filter { $0.isPending } }
    var confirmed: [FieldEvent] { events.filter { $0.isUpcoming && ($0.accepted ?? false) } }
    var past: [FieldEvent]      { events.filter { $0.isCompleted } }
}