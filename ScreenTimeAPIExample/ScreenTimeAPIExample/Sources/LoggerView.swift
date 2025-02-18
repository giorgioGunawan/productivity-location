import SwiftUI

struct LoggerView: View {
    @ObservedObject private var logger = Logger.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(logger.logs.reversed()) { entry in
                                LogEntryView(entry: entry)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: logger.logs.count) { _ in
                        if let lastId = logger.logs.last?.id {
                            proxy.scrollTo(lastId)
                        }
                    }
                }
            }
            .navigationTitle("Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        logger.clearLogs()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LogEntryView: View {
    let entry: Logger.LogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Text(entry.type.symbol)
                Text(entry.message)
                    .font(.system(.body, design: .monospaced))
            }
            Text(entry.formattedTimestamp)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    LoggerView()
} 