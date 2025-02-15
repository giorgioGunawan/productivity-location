import SwiftUI

struct SwiftUIView: View {
    // Color constants
    private let mainGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 125/255, green: 74/255, blue: 255/255),  // Purple
            Color(red: 64/255, green: 93/255, blue: 230/255)    // Blue
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let mainPurple = Color(red: 125/255, green: 74/255, blue: 255/255)
    private let mainBlue = Color(red: 64/255, green: 93/255, blue: 230/255)
    
    @EnvironmentObject var model: BlockingApplicationModel
    @State var isPresented = false
    @State private var scheduleStartHour: Int
    @State private var scheduleStartMinute: Int
    @State private var scheduleEndHour: Int
    @State private var scheduleEndMinute: Int
    @StateObject var appBlocker = AppBlocker.shared
    
    @State private var showingAddSchedule = false
    @State private var currentSteps: Int = 0
    @State private var showingCelebration = false
    @State private var showingStepsWidget = false
    @State private var selectedSchedule: BlockSchedule?
    
    init() {
        let calendar = Calendar.current
        let now = Date()
        let oneHourFromNow = calendar.date(byAdding: .hour, value: 1, to: now)!
        
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let laterComponents = calendar.dateComponents([.hour, .minute], from: oneHourFromNow)
        
        _scheduleStartHour = State(initialValue: nowComponents.hour ?? 0)
        _scheduleStartMinute = State(initialValue: nowComponents.minute ?? 0)
        _scheduleEndHour = State(initialValue: laterComponents.hour ?? 1)
        _scheduleEndMinute = State(initialValue: laterComponents.minute ?? 0)
    }
    var view: some View {
        VStack {
            // Apps List button
            HStack {
                Spacer()
                Button(action: { isPresented.toggle() }) {
                    Text("Apps List")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color(.systemGray4), radius: 10, x: 0, y: 5)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(.systemGray3), lineWidth: 2)
                        )
                }
                .familyActivityPicker(isPresented: $isPresented, selection: $model.newSelection)
                .padding()
            }
            
            // Schedules List
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(model.schedules) { schedule in
                        VStack {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Start: \(schedule.formattedStartTime())")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text("End: \(schedule.formattedEndTime())")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if schedule.isActive {
                                    Text("Active")
                                        .foregroundColor(.green)
                                        .font(.system(size: 16, weight: .bold))
                                        .padding(6)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2)) // Grey card background
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .onTapGesture {
                                selectedSchedule = schedule
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8) // Space between cards
            }
            .background(Color(.systemBackground))
            .sheet(item: $selectedSchedule) { schedule in
                ScheduleDetailView(schedule: schedule, onDelete: {
                    if let index = model.schedules.firstIndex(where: { $0.id == schedule.id }) {
                        model.schedules.remove(at: index)
                        appBlocker.removeAndCheckSchedule(schedule)
                    }
                    selectedSchedule = nil // Clear the selection instead of using showingDrawer
                }, onClose: {
                    selectedSchedule = nil // Clear the selection instead of using showingDrawer
                })
            }
            
            // Steps Widget (only show when unblocking temporarily)
            if showingStepsWidget {
                VStack(spacing: 8) {
                    Text("Steps Taken")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(mainPurple)
                    
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [mainPurple.opacity(0.1), mainBlue.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .stroke(mainGradient, lineWidth: 8)
                            .frame(width: 150, height: 150)
                        
                        VStack(spacing: 0) {
                            Text("\(currentSteps)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(mainPurple)
                            Text("/ 15")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(mainBlue)
                        }
                    }
                }
                .padding()
                .transition(.scale)
            }
            
            // Add Schedule Button
            Button(action: { showingAddSchedule = true }) {
                Text("Add Schedule")
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color(.systemGray4), radius: 8, x: 0, y: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(.systemGray3), lineWidth: 2)
                    )
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            // Action buttons
            VStack(spacing: 16) {
                Button(action: { unblockTemp() }) {
                    Text("Unblock 5 Minutes")
                        .frame(maxWidth: .infinity)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(mainGradient)
                                .opacity(0.8)
                                .shadow(color: mainPurple.opacity(0.5), radius: 8, x: 0, y: 4)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .background(Color(.systemBackground))
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingAddSchedule) {
            NavigationView {
                Form {
                    Section(header: Text("Start Time")) {
                        HStack {
                            Picker("Hour", selection: $scheduleStartHour) {
                                ForEach(0...23, id: \.self) { hour in
                                    Text(String(format: "%02d", hour))
                                }
                            }
                            Text(":")
                            Picker("Minute", selection: $scheduleStartMinute) {
                                ForEach(0...59, id: \.self) { minute in
                                    Text(String(format: "%02d", minute))
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("End Time")) {
                        HStack {
                            Picker("Hour", selection: $scheduleEndHour) {
                                ForEach(0...23, id: \.self) { hour in
                                    Text(String(format: "%02d", hour))
                                }
                            }
                            Text(":")
                            Picker("Minute", selection: $scheduleEndMinute) {
                                ForEach(0...59, id: \.self) { minute in
                                    Text(String(format: "%02d", minute))
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Add Schedule")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingAddSchedule = false
                    },
                    trailing: Button("Save") {
                        let newSchedule = BlockSchedule(
                            startHour: scheduleStartHour,
                            startMinute: scheduleStartMinute,
                            endHour: scheduleEndHour,
                            endMinute: scheduleEndMinute
                        )
                        model.schedules.append(newSchedule)
                        appBlocker.startBlockingSchedule(schedule: newSchedule)
                        showingAddSchedule = false
                    }
                )
            }
        }
        .onReceive(appBlocker.$stepCount) { newCount in
            print("Received new count in view: \(newCount)")
            withAnimation {
                currentSteps = newCount
                if newCount >= 15 && !showingCelebration {
                    showingCelebration = true
                }
            }
        }
        .alert("Congratulations! 🎉", isPresented: $showingCelebration) {
            Button("OK", role: .cancel) {
                withAnimation {
                    showingStepsWidget = false
                }
                appBlocker.stopStepCountUpdates()
                appBlocker.unblockAllApps()
            }
        } message: {
            Text("You've reached 15 steps! Your apps are now unblocked.")
        }
    }

    var body: some View {
        view
    }
    
    private func unblockTemp() {
        withAnimation {
            showingStepsWidget = true
        }
        appBlocker.unblockTemp()
    }
}

// New View for Schedule Details
struct ScheduleDetailView: View {
    var schedule: BlockSchedule
    var onDelete: () -> Void
    var onClose: () -> Void // Closure to handle close action

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Schedule Details")) {
                    Text("Start: \(schedule.formattedStartTime())")
                    Text("End: \(schedule.formattedEndTime())")
                    Text("Active: \(schedule.isActive ? "Yes" : "No")")
                }
                Section {
                    Button(action: onDelete) {
                        Text("Delete Schedule")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Schedule Info")
            .navigationBarItems(trailing: Button("Close") {
                onClose() // Call the close action
            })
        }
    }
}
