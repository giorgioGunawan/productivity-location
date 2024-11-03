import SwiftUI

struct SwiftUIView: View {
    // Add these color constants at the top of the view
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
    @State private var blockHours: Int = 0
    @State private var blockMinutes: Int = 10  // Default 10 minutes
    @StateObject var appBlocker = AppBlocker()

    @State var gioStepCount: Int = 0
    
    @State private var blockStartHourText: String = ""
    @State private var blockStartMinuteText: String = ""
    @State private var blockEndHourText: String = ""
    @State private var blockEndMinuteText: String = ""
    
    @State private var currentSteps: Int = 0
    
    @State private var showingCelebration = false
    
    var view: some View {
            VStack {
                // Apps List button
                HStack {
                    Spacer()
                    Button(action: { isPresented.toggle() }) {
                        Text("Apps List")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(mainGradient)
                                    .shadow(color: mainPurple.opacity(0.3), radius: 10, x: 0, y: 5)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .familyActivityPicker(isPresented: $isPresented, selection: $model.newSelection)
                    .padding()
                }

                Spacer()

                // Steps counter
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
                .padding(.bottom, 30)

                // Time selection area
                HStack(spacing: 30) {
                    // Hours picker
                    VStack(alignment: .center, spacing: 8) {
                        Text("Hours")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(mainPurple)
                        
                        Picker("Hours", selection: $blockHours) {
                            ForEach(0...23, id: \.self) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .frame(width: 100)
                        .background(mainPurple.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: mainPurple.opacity(0.2), radius: 10, x: 0, y: 5)
                    )
                    
                    // Minutes picker
                    VStack(alignment: .center, spacing: 8) {
                        Text("Minutes")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(mainBlue)
                        
                        Picker("Minutes", selection: $blockMinutes) {
                            ForEach(0...59, id: \.self) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .frame(width: 100)
                        .background(mainBlue.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: mainBlue.opacity(0.2), radius: 10, x: 0, y: 5)
                    )
                }
                .padding(.horizontal)
                .padding(.vertical, 20)

                Spacer()

                // Action buttons
                VStack(spacing: 16) {
                    Button(action: { startBlocking() }) {
                        Text("Start Blocking")
                            .frame(maxWidth: .infinity)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(mainGradient)
                                    .shadow(color: mainPurple.opacity(0.5), radius: 8, x: 0, y: 4)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .disabled(appBlocker.startedBlocking == true)
                    .opacity(appBlocker.startedBlocking ? 0.3 : 1)
                    
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
                    .disabled(appBlocker.startedBlocking == false)
                    .opacity(appBlocker.startedBlocking ? 1 : 0.3)
                    
                    Button(action: { unblockAll() }) {
                        Text("Unblock All")
                            .frame(maxWidth: .infinity)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(mainGradient)
                                    .opacity(0.6)
                                    .shadow(color: mainPurple.opacity(0.5), radius: 8, x: 0, y: 4)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .disabled(appBlocker.startedBlocking == false)
                    .opacity(appBlocker.startedBlocking ? 1 : 0.3)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
        }
        .onReceive(appBlocker.$stepCount) { newCount in
            print("Received new count in view: \(newCount)")
            withAnimation {
                currentSteps = newCount
                // Add celebration check
                if newCount >= 15 && !showingCelebration {
                    showingCelebration = true
                }
            }
        }
        .onChange(of: appBlocker.startedBlocking) { newValue in
            print("View detected started blocking: \(newValue)")

        }
        .alert("Congratulations! 🎉", isPresented: $showingCelebration) {
            Button("OK", role: .cancel) {
                // Reset steps after celebration
                appBlocker.stopStepCountUpdates()
                appBlocker.unblockAllApps()
            }
        } message: {
            Text("You've reached 15 steps! Your apps are now unblocked.")
        }
    }

    var body: some View {
        view
            .onReceive(appBlocker.$stepCount) { newCount in
                print("Received new count in view: \(newCount)")
                withAnimation {
                    currentSteps = newCount
                    // Add celebration check
                    if newCount >= 15 && !showingCelebration {
                        showingCelebration = true
                    }
                }
            }
    }
    
    private func startBlocking() {
        // Don't allow 0 duration
        guard blockHours > 0 || blockMinutes > 0 else { return }
        
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Calculate end time by adding hours and minutes to current time
        guard let endDate = calendar.date(byAdding: .hour, value: blockHours, to: currentDate),
              let finalEndDate = calendar.date(byAdding: .minute, value: blockMinutes, to: endDate) else {
            return
        }
        
        let endComponents = calendar.dateComponents([.hour, .minute], from: finalEndDate)
        let startComponents = calendar.dateComponents([.hour, .minute], from: currentDate)
        
        appBlocker.startBlockingTimer(
            blockStartHour: startComponents.hour ?? 0,
            blockEndHour: endComponents.hour ?? 0,
            blockStartMinute: startComponents.minute ?? 0,
            blockEndMinute: endComponents.minute ?? 0
        )
    }
    
    private func unblockAll() {
        appBlocker.stopStepCountUpdates()
        appBlocker.unblockAllApps()
    }
    
    private func unblockTemp() {
        appBlocker.unblockTemp()
    }
}
