import SwiftUI
import AppKit

/// Appends feedback as JSON lines to ~/Library/Application Support/Am I Artificially Intelligent/feedback.jsonl.
/// Nothing leaves the Mac.
public final class FeedbackStore: @unchecked Sendable {
    public static let shared = FeedbackStore()

    public let fileURL: URL

    init(directory: URL? = nil) {
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Am I Artificially Intelligent", isDirectory: true)
        fileURL = base.appendingPathComponent("feedback.jsonl")
    }

    private struct Entry: Encodable {
        let date: Date
        let kind: String
        let message: String
    }

    public func save(kind: String, message: String) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        var line = try encoder.encode(Entry(date: Date(), kind: kind, message: message))
        line.append(0x0A)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let handle = try FileHandle(forWritingTo: fileURL)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: line)
        } else {
            try line.write(to: fileURL)
        }
    }

    public func revealInFinder() {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        } else {
            try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            NSWorkspace.shared.open(fileURL.deletingLastPathComponent())
        }
    }
}

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var kind = "Idea"
    @State private var message = ""
    @State private var error: String?

    private let kinds = ["Idea", "Bug", "Question I'd add", "Other"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Send Feedback").font(.title3.bold())
            Picker("Kind", selection: $kind) {
                ForEach(kinds, id: \.self) { Text($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            TextEditor(text: $message)
                .font(.body)
                .frame(height: 120)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.quaternary))
            Text("Saved on this Mac only, to \(FeedbackStore.shared.fileURL.lastPathComponent) in Application Support.")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let error {
                Text(error).font(.caption).foregroundStyle(.red)
            }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    do {
                        try FeedbackStore.shared.save(kind: kind, message: message)
                        dismiss()
                    } catch {
                        self.error = "Couldn't save: \(error.localizedDescription)"
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
