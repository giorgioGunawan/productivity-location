import Foundation
import FamilyControls
import ManagedSettings
import SwiftUI

// Add protocol for AppBlocker interface to avoid direct dependency
protocol AppBlockerProtocol {
    func startBlockingSchedule(schedule: BlockSchedule)
    func removeAndCheckSchedule(_ schedule: BlockSchedule)
}

// Add protocol for Logger interface
protocol LoggerProtocol {
    static func log(_ message: String, type: LogType)
}

enum LogType {
    case info
    case warning
    case error
    case success
}

final class BlockingApplicationModel: ObservableObject {
    static let shared = BlockingApplicationModel()
    static let appGroupID = "group.com.productivityone.productivityApp"
    
    @Published var newSelection: FamilyActivitySelection = .init() {
        didSet {
            saveSelectedAppTokens()
        }
    }
    
    @Published var schedules: [BlockSchedule] = [] {
        didSet {
            saveSchedules()
        }
    }
    
    @Published var newScheduleName: String = "New Schedule"
    
    @Published var isProcessing: Bool = false
    
    // Computed property for app tokens
    var selectedAppsTokens: Set<ApplicationToken> {
        newSelection.applicationTokens
    }
    
    private let selectedAppsKey = "SelectedAppsTokens"
    private let schedulesKey = "SavedSchedules"
    
    // Add notification center for communication
    private let notificationCenter: NotificationCenter
    
    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        loadSelectedAppTokens()
        loadSchedules()
    }
    
    // App tokens persistence
    private func saveSelectedAppTokens() {
        guard let groupUserDefaults = UserDefaults(suiteName: Self.appGroupID) else {
            print("❌ Failed to access App Group UserDefaults")
            return
        }
        
        do {
            let encodedData = try JSONEncoder().encode(selectedAppsTokens)
            groupUserDefaults.set(encodedData, forKey: selectedAppsKey)
            groupUserDefaults.synchronize()
        } catch {
            print("❌ Failed to encode tokens: \(error)")
        }
    }
    
    private func loadSelectedAppTokens() {
        guard let groupUserDefaults = UserDefaults(suiteName: Self.appGroupID) else {
            print("❌ Failed to access App Group UserDefaults")
            return
        }
        
        if let encodedData = groupUserDefaults.data(forKey: selectedAppsKey),
           let tokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: encodedData) {
            newSelection.applicationTokens = tokens
            print("✅ Loaded tokens from shared storage")
        }
    }
    
    // Schedules persistence
    private func saveSchedules() {
        guard let groupUserDefaults = UserDefaults(suiteName: Self.appGroupID) else { return }
        if let encoded = try? JSONEncoder().encode(schedules) {
            groupUserDefaults.set(encoded, forKey: schedulesKey)
            groupUserDefaults.synchronize()
        }
    }
    
    private func loadSchedules() {
        guard let groupUserDefaults = UserDefaults(suiteName: Self.appGroupID) else { return }
        if let data = groupUserDefaults.data(forKey: schedulesKey),
           let decoded = try? JSONDecoder().decode([BlockSchedule].self, from: data) {
            schedules = decoded
        }
    }
    
    func moveSchedule(from source: IndexSet, to destination: Int) {
        schedules.move(fromOffsets: source, toOffset: destination)
        saveSchedules() // Make sure the new order is persisted
    }
    
    func addScheduleOptimistically(_ schedule: BlockSchedule) {
        // Immediately update UI on main thread
        DispatchQueue.main.async {
            self.schedules.append(schedule)
            
            // Perform background work
            Task {
                self.isProcessing = true
                do {
                    // Save to UserDefaults
                    self.saveSchedules()
                    
                    // Notify AppBlocker
                    self.notificationCenter.post(
                        name: Notification.Name("StartBlockingSchedule"),
                        object: nil,
                        userInfo: ["schedule": schedule]
                    )
                } catch {
                    // Rollback on error
                    DispatchQueue.main.async {
                        self.schedules.removeAll { $0.id == schedule.id }
                        print("Failed to save schedule: \(error)")
                    }
                }
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
            }
        }
    }
    
    func deleteScheduleOptimistically(_ schedule: BlockSchedule) {
        // Store schedule for potential rollback
        let scheduleIndex = schedules.firstIndex(of: schedule)
        
        // Immediately update UI on main thread
        DispatchQueue.main.async {
            self.schedules.removeAll { $0.id == schedule.id }
            
            // Perform background work
            Task {
                self.isProcessing = true
                do {
                    // Save to UserDefaults
                    self.saveSchedules()
                    
                    // Notify AppBlocker
                    self.notificationCenter.post(
                        name: Notification.Name("RemoveSchedule"),
                        object: nil,
                        userInfo: ["schedule": schedule]
                    )
                } catch {
                    // Rollback on error
                    if let index = scheduleIndex {
                        DispatchQueue.main.async {
                            self.schedules.insert(schedule, at: index)
                            print("Failed to delete schedule: \(error)")
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
            }
        }
    }
}
