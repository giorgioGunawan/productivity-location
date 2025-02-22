import SwiftUI

struct DebugView: View {
    @Environment(\.dismiss) private var dismiss
    let debugInfo: String
    let appBlocker: AppBlocker
    let onRestartOnboarding: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Status")) {
                    Text(debugInfo)
                        .font(.system(.caption, design: .monospaced))
                        .lineSpacing(2)
                    
                    if appBlocker.activeSchedules.isEmpty {
                        Text("No Active Schedules")
                            .foregroundColor(.gray)
                            .font(.system(.caption))
                    } else {
                        ForEach(Array(appBlocker.activeSchedules), id: \.id) { schedule in
                            Text("SID: \(String(schedule.id.uuidString.prefix(5))), \(schedule.formattedStartTime()) - \(schedule.formattedEndTime())")
                                .font(.system(.caption))
                        }
                    }
                }
                
                Section(header: Text("Actions")) {
                    Button("Restart Onboarding") {
                        onRestartOnboarding()
                        dismiss()
                    }
                    
                    Button("Unblock All Apps") {
                        appBlocker.unblockAllApps()
                    }
                    
                    Button("Unblock 15 seconds") {
                        appBlocker.unblockApplicationsTemporarily15seconds()
                    }
                    
                    Button("Unblock 5 mins") {
                        appBlocker.unblockApplicationsTemporarily5minutes()
                    }
                    
                    NavigationLink("Show Logs") {
                        LoggerView()
                    }
                    
                    Button("Refresh Set") {
                        appBlocker.refreshSet()
                    }
                }
            }
            .navigationTitle("Debug Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
        }
    }
} 