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
    @State private var editMode = EditMode.inactive
    
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
        VStack(spacing: Theme.standardPadding) {
            // Header
            HStack {
                Spacer()
                Button(action: { isPresented.toggle() }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Add Apps")
                            .font(Theme.subtitleStyle)
                    }
                    .foregroundColor(Theme.mainPurple)
                    .frame(height: Theme.minimumTapTarget)
                    .padding(.horizontal, Theme.standardPadding)
                    .background(
                        Capsule()
                            .fill(Theme.mainPurple.opacity(0.1))
                    )
                }
                .familyActivityPicker(isPresented: $isPresented, selection: $model.newSelection)
            }
            .padding(.horizontal, Theme.standardPadding)
            .padding(.top, Theme.standardPadding)
            
            // Schedules List
            List {
                ForEach(model.schedules) { schedule in
                    ScheduleCard(schedule: schedule) {
                        HapticManager.shared.impact(style: .medium)
                        selectedSchedule = schedule
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.standardCornerRadius)
                            .stroke(Theme.mainPurple.opacity(0.3), lineWidth: 2)
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                }
                .onMove { source, destination in
                    HapticManager.shared.impact(style: .light)
                    model.moveSchedule(from: source, to: destination)
                }
            }
            .listStyle(PlainListStyle())
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.impact(style: .medium)
                        editMode = editMode == .active ? .inactive : .active
                    }) {
                        Image(systemName: editMode == .active ? "checkmark.circle.fill" : "list.bullet")
                            .foregroundColor(Theme.mainPurple)
                    }
                }
            }
            
            // Action Buttons
            VStack(spacing: Theme.standardPadding) {
                Button(action: { showingAddSchedule = true }) {
                    HStack {
                        Image(systemName: "clock.fill")
                        Text("Add Schedule")
                    }
                    .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
                    .font(Theme.subtitleStyle)
                    .foregroundColor(.white)
                    .background(Theme.mainGradient)
                    .cornerRadius(Theme.largeCornerRadius)
                    .shadow(radius: 5)
                }
                
                Button(action: { unblockTemp() }) {
                    HStack {
                        Image(systemName: "figure.walk.circle.fill")
                        Text("Take a Break (5 min)")
                    }
                    .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
                    .font(Theme.subtitleStyle)
                    .foregroundColor(Theme.mainPurple)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.largeCornerRadius)
                            .fill(Theme.background)
                            .shadow(radius: 5)
                    )
                }
            }
            .padding(.horizontal, Theme.standardPadding)
            .padding(.bottom, Theme.standardPadding)
            
            if showingStepsWidget {
                StepsWidget(currentSteps: currentSteps) {
                    withAnimation {
                        showingStepsWidget = false
                    }
                    appBlocker.stopStepCountUpdates()
                    appBlocker.unblockAllApps()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingAddSchedule) {
            NavigationView {
                Form {
                    Section {
                        TextField("Schedule Name", text: .init(
                            get: { model.newScheduleName },
                            set: { model.newScheduleName = $0 }
                        ))
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Start Time")
                                .font(Theme.subtitleStyle)
                                .foregroundColor(Theme.mainPurple)
                            
                            HStack(spacing: 16) {
                                TimePickerField(
                                    value: $scheduleStartHour,
                                    range: 0...23,
                                    label: "Hour"
                                )
                                
                                Text(":")
                                    .font(Theme.titleStyle)
                                    .foregroundColor(.secondary)
                                
                                TimePickerField(
                                    value: $scheduleStartMinute,
                                    range: 0...59,
                                    label: "Minute"
                                )
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("End Time")
                                .font(Theme.subtitleStyle)
                                .foregroundColor(Theme.mainPurple)
                            
                            HStack(spacing: 16) {
                                TimePickerField(
                                    value: $scheduleEndHour,
                                    range: 0...23,
                                    label: "Hour"
                                )
                                
                                Text(":")
                                    .font(Theme.titleStyle)
                                    .foregroundColor(.secondary)
                                
                                TimePickerField(
                                    value: $scheduleEndMinute,
                                    range: 0...59,
                                    label: "Minute"
                                )
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .navigationTitle("Add Schedule")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingAddSchedule = false
                    }
                    .foregroundColor(Theme.mainPurple),
                    trailing: Button("Save") {
                        HapticManager.shared.notification(type: .success)
                        let newSchedule = BlockSchedule(
                            startHour: scheduleStartHour,
                            startMinute: scheduleStartMinute,
                            endHour: scheduleEndHour,
                            endMinute: scheduleEndMinute,
                            name: model.newScheduleName
                        )
                        model.schedules.append(newSchedule)
                        appBlocker.startBlockingSchedule(schedule: newSchedule)
                        model.newScheduleName = "New Schedule"
                        showingAddSchedule = false
                    }
                    .font(.headline)
                    .foregroundColor(Theme.mainPurple)
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
        .sheet(item: $selectedSchedule) { schedule in
            ScheduleDetailView(
                schedule: Binding(
                    get: { schedule },
                    set: { newSchedule in
                        if let index = model.schedules.firstIndex(where: { $0.id == schedule.id }) {
                            model.schedules[index] = newSchedule
                        }
                    }
                ),
                onDelete: {
                    if let index = model.schedules.firstIndex(where: { $0.id == schedule.id }) {
                        model.schedules.remove(at: index)
                        selectedSchedule = nil
                    }
                },
                onClose: {
                    selectedSchedule = nil
                }
            )
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
        HapticManager.shared.impact(style: .medium)
        withAnimation {
            showingStepsWidget = true
        }
        appBlocker.unblockTemp()
    }
}

// New View for Schedule Details
struct ScheduleDetailView: View {
    @Binding var schedule: BlockSchedule
    var onDelete: () -> Void
    var onClose: () -> Void
    @State private var name: String
    
    init(schedule: Binding<BlockSchedule>, onDelete: @escaping () -> Void, onClose: @escaping () -> Void) {
        self._schedule = schedule
        self._name = State(initialValue: schedule.wrappedValue.name)
        self.onDelete = onDelete
        self.onClose = onClose
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Schedule Name", text: $name)
                        .onChange(of: name) { newValue in
                            schedule.name = newValue
                        }
                }
                
                Section {
                    DetailRow(title: "Start Time", value: schedule.formattedStartTime())
                    DetailRow(title: "End Time", value: schedule.formattedEndTime())
                    DetailRow(title: "Status", value: schedule.isActive ? "Active" : "Inactive")
                }
                
                Section {
                    Button(action: {
                        HapticManager.shared.notification(type: .warning)
                        onDelete()
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Schedule")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
                    }
                }
            }
            .navigationTitle("Schedule Details")
            .navigationBarItems(trailing: 
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
            )
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(Theme.bodyStyle)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(Theme.subtitleStyle)
                .foregroundColor(.primary)
        }
    }
}

// Add a new ScheduleCard view
struct ScheduleCard: View {
    let schedule: BlockSchedule
    let onTap: () -> Void
    
    var isCurrentlyActive: Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        let startTimeInMinutes = schedule.startHour * 60 + schedule.startMinute
        let endTimeInMinutes = schedule.endHour * 60 + schedule.endMinute
        let currentTimeInMinutes = currentHour * 60 + currentMinute
        
        if endTimeInMinutes > startTimeInMinutes {
            // Same day schedule
            return currentTimeInMinutes >= startTimeInMinutes && currentTimeInMinutes <= endTimeInMinutes
        } else {
            // Overnight schedule
            return currentTimeInMinutes >= startTimeInMinutes || currentTimeInMinutes <= endTimeInMinutes
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(schedule.name)
                        .font(Theme.subtitleStyle)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text(schedule.formattedStartTime())
                            .font(Theme.bodyStyle)
                            .foregroundColor(.secondary)
                        Text("-")
                            .font(Theme.bodyStyle)
                            .foregroundColor(.secondary)
                        Text(schedule.formattedEndTime())
                            .font(Theme.bodyStyle)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if schedule.isActive && isCurrentlyActive {
                    Label("Active", systemImage: "checkmark.circle.fill")
                        .font(Theme.bodyStyle)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(Theme.standardPadding)
            .background(Theme.background)
            .cornerRadius(Theme.standardCornerRadius)
            .shadow(radius: 5)
        }
    }
}

struct StepsWidget: View {
    let currentSteps: Int
    var onClose: () -> Void
    
    // Animation states
    @State private var isRotating = false
    @State private var isGlowing = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header with close button
            HStack {
                Label("Break Time", systemImage: "figure.walk.motion")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.7))
                        .shadow(radius: 2)
                }
            }
            
            // Progress Circle
            ZStack {
                // Outer glow
                Circle()
                    .stroke(Theme.mainGradient, lineWidth: 1)
                    .blur(radius: 8)
                    .opacity(isGlowing ? 0.8 : 0.4)
                    .frame(width: 220, height: 220)
                
                // Background circles
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .stroke(Theme.mainPurple.opacity(0.2), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                // Animated dots around the circle
                ForEach(0..<8) { index in
                    Circle()
                        .fill(Theme.mainGradient)
                        .frame(width: 8, height: 8)
                        .offset(y: -100)
                        .rotationEffect(.degrees(Double(index) * 45))
                        .rotationEffect(.degrees(isRotating ? 360 : 0))
                        .opacity(currentSteps > 0 ? 1 : 0)
                }
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(min(currentSteps, 15)) / 15.0)
                    .stroke(
                        Theme.mainGradient,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: currentSteps)
                
                // Center content
                VStack(spacing: 8) {
                    Text("\(currentSteps)")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                    
                    Text("steps to unlock")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.vertical, 20)
            
            // Progress text
            Text("\(15 - currentSteps) steps remaining")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )
        }
        .padding(32)
        .background(
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.8),
                        Color(red: 0.2, green: 0.2, blue: 0.3).opacity(0.9)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Animated background particles
                ForEach(0..<15) { index in
                    Circle()
                        .fill(Theme.mainGradient)
                        .frame(width: 4, height: 4)
                        .blur(radius: 1)
                        .opacity(0.5)
                        .offset(x: .random(in: -100...100), y: .random(in: -100...100))
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Theme.mainPurple.opacity(0.3), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                isRotating = true
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isGlowing = true
            }
        }
        .onChange(of: currentSteps) { newValue in
            if newValue == 15 {
                HapticManager.shared.notification(type: .success)
            } else if newValue > 0 {
                HapticManager.shared.impact(style: .light)
            }
        }
    }
}

struct TimePickerField: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let label: String
    
    var body: some View {
        Picker(label, selection: $value) {
            ForEach(range, id: \.self) { number in
                Text(String(format: "%02d", number))
                    .tag(number)
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 100)
        .clipped()
    }
}

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
