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

    func accept(_ event: FieldEvent) async { await callRPC("accept_event", params: EventIdParam(p_event_id: event.id)) }
    func decline(_ event: FieldEvent) async { await callRPC("decline_event", params: EventIdParam(p_event_id: event.id)) }

    func checkIn(_ event: FieldEvent, lat: Double?, lng: Double?) async {
        await callRPC("check_in_event", params: GeoParam(p_event_id: event.id, p_lat: lat, p_lng: lng))
    }

    func checkOut(_ event: FieldEvent, lat: Double?, lng: Double?) async {
        await callRPC("check_out_event", params: GeoParam(p_event_id: event.id, p_lat: lat, p_lng: lng))
    }

    func submitReport(_ event: FieldEvent, units: Int, samples: Int, feedback: String, photos: Int) async {
        await callRPC("submit_report", params: ReportParam(
            p_event_id: event.id, p_units: units, p_samples: samples, p_feedback: feedback, p_photos: photos))
    }

    private func callRPC(_ fn: String, params: some Encodable & Sendable) async {
        do {
            try await client.rpc(fn, params: params).execute()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private struct EventIdParam: Encodable, Sendable { let p_event_id: Int }
    private struct GeoParam: Encodable, Sendable { let p_event_id: Int; let p_lat: Double?; let p_lng: Double? }
    private struct ReportParam: Encodable, Sendable {
        let p_event_id: Int; let p_units: Int; let p_samples: Int; let p_feedback: String; let p_photos: Int
    }

    // Grouped for display. Today's active demos surface in their own section.
    var todays: [FieldEvent] { events.filter { $0.isToday && !$0.isCompleted } }
    var needsConfirmation: [FieldEvent] { events.filter { $0.needsConfirmation && !$0.isToday } }
    var pending: [FieldEvent]  { events.filter { $0.isPending && !$0.isToday } }
    var confirmed: [FieldEvent] { events.filter { $0.isUpcoming && ($0.accepted ?? false) && !$0.isToday } }
    var past: [FieldEvent]      { events.filter { $0.isCompleted } }
}