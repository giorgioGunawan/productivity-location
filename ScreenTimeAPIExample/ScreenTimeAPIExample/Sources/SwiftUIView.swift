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
    @State private var scheduleStartHour: Int = 00  // Default 12 AM
    @State private var scheduleStartMinute: Int = 0
    @State private var scheduleEndHour: Int = 01    // Default 1 AM
    @State private var scheduleEndMinute: Int = 0
    @StateObject var appBlocker = AppBlocker()

    @State var gioStepCount: Int = 0
    
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
                VStack(spacing: 20) {
                    Text("I want to block my apps between...")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(mainPurple)
                        .padding(.bottom, 10)
                    
                    // Start Time
                    HStack(spacing: 30) {
                        Text("Start")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(mainPurple)
                            .frame(width: 70, alignment: .leading)
                        
                        // Hours
                        HStack {
                            Picker("Start Hour", selection: $scheduleStartHour) {
                                ForEach(0...23, id: \.self) { hour in
                                    Text(String(format: "%02d", hour)).tag(hour)
                                }
                            }
                            .frame(width: 80)
                            
                            Text(":")
                                .font(.system(size: 20, weight: .bold))
                            
                            // Minutes
                            Picker("Start Minute", selection: $scheduleStartMinute) {
                                ForEach(0...59, id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .frame(width: 80)
                        }
                        .background(mainPurple.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: mainPurple.opacity(0.2), radius: 10, x: 0, y: 5)
                    )
                    
                    // End Time
                    HStack(spacing: 30) {
                        Text("End")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(mainBlue)
                            .frame(width: 70, alignment: .leading)
                        
                        // Hours
                        HStack {
                            Picker("End Hour", selection: $scheduleEndHour) {
                                ForEach(0...23, id: \.self) { hour in
                                    Text(String(format: "%02d", hour)).tag(hour)
                                }
                            }
                            .frame(width: 80)
                            
                            Text(":")
                                .font(.system(size: 20, weight: .bold))
                            
                            // Minutes
                            Picker("End Minute", selection: $scheduleEndMinute) {
                                ForEach(0...59, id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .frame(width: 80)
                        }
                        .background(mainBlue.opacity(0.1))
                        .cornerRadius(12)
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
        appBlocker.startBlockingSchedule(
            scheduleStartHour: scheduleStartHour,
            scheduleStartMinute: scheduleStartMinute,
            scheduleEndHour: scheduleEndHour,
            scheduleEndMinute: scheduleEndMinute
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
