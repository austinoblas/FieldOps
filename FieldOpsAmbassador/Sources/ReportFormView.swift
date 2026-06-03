import SwiftUI

struct ReportFormView: View {
    let event: FieldEvent
    let vm: ScheduleViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var units = ""
    @State private var samples = ""
    @State private var photos = ""
    @State private var feedback = ""
    @State private var busy = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Results") {
                    field("Units sold", text: $units)
                    field("Samples given", text: $samples)
                    field("Photos taken", text: $photos)
                }
                Section("Feedback") {
                    TextField("How did it go?", text: $feedback, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("Event Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        busy = true
                        Task {
                            await vm.submitReport(
                                event,
                                units: Int(units) ?? 0,
                                samples: Int(samples) ?? 0,
                                feedback: feedback,
                                photos: Int(photos) ?? 0
                            )
                            busy = false
                            dismiss()
                        }
                    }
                    .disabled(busy)
                }
            }
        }
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
        }
    }
}
