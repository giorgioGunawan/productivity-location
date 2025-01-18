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
            List {
                ForEach(model.schedules) { schedule in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Start: \(schedule.formattedStartTime())")
                                .font(.system(size: 16, weight: .medium))
                            Text("End: \(schedule.formattedEndTime())")
                                .font(.system(size: 16, weight: .medium))
                        }
                        Spacer()
                        if schedule.isActive {
                            Text("Active")
                                .foregroundColor(.green)
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onDelete { indexSet in
                    // Get the schedules that are being deleted
                    let schedulesToDelete = indexSet.map { model.schedules[$0] }
                    
                    // Remove them from the model
                    model.schedules.remove(atOffsets: indexSet)
                    
                    // Check each deleted schedule
                    for deletedSchedule in schedulesToDelete {
                        appBlocker.removeAndCheckSchedule(deletedSchedule)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .background(Color(.systemBackground))
            
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
