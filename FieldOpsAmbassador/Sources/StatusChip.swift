import SwiftUI

/// Color-coded status pill shared across schedule and admin lists.
struct StatusChip: View {
    let event: FieldEvent

    var body: some View {
        Text(event.statusLabel)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }

    private var color: Color {
        switch event.statusLabel {
        case "Completed":         return .green
        case "Checked in":        return .green
        case "Awaiting report":   return .orange
        case "Pending approval":  return .orange
        case "Needs confirmation": return Theme.brand
        default:                  return .blue   // Confirmed
        }
    }
}
