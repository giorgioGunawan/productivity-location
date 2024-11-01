import SwiftUI

struct DismissKeyboardWrapper<Content: View>: UIViewControllerRepresentable {
    var content: () -> Content

    func makeUIViewController(context: Context) -> UIViewController {
        DismissKeyboardViewController(rootView: content())
    }

    
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

class DismissKeyboardViewController<Content: View>: UIHostingController<Content> {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

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
    @State private var blockStartHour: Int = 0
    @State private var blockStartMinute: Int = 0
    @State private var blockEndHour: Int = 1
    @State private var blockEndMinute: Int = 0
    @StateObject var appBlocker = AppBlocker()
    
    @State private var blockStartHourText: String = ""
    @State private var blockStartMinuteText: String = ""
    @State private var blockEndHourText: String = ""
    @State private var blockEndMinuteText: String = ""
    
    @State var blockStart = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
    @State var blockEnd = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: Date())!
    
    var body: some View {
        DismissKeyboardWrapper {
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
                            Text("\(appBlocker.stepCount)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(mainPurple)
                                .id(appBlocker.stepCount)
                            Text("/ 15")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(mainBlue)
                        }
                    }
                }
                .padding(.bottom, 30)

                // Time selection area
                HStack(spacing: 30) {
                    // Start time
                    VStack(alignment: .center, spacing: 8) {
                        Text("Start Time")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(mainPurple)
                        
                        DatePicker("", selection: $blockStart, displayedComponents: .hourAndMinute)
                            .labelsHidden()
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
                    
                    // End time
                    VStack(alignment: .center, spacing: 8) {
                        Text("End Time")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(mainBlue)
                        
                        DatePicker("", selection: $blockEnd, displayedComponents: .hourAndMinute)
                            .labelsHidden()
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
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            let calendar = Calendar.current
            let currentDate = Date()

            // Set blockStart to the current time
            blockStart = currentDate

            // Update blockEnd to 10 minutes from the current time
            let plus10Minutes = calendar.date(byAdding: .minute, value: 10, to: currentDate) ?? currentDate
            blockEnd = plus10Minutes
        }
        .onChange(of: appBlocker.stepCount) { newValue in
            print("View detected step count change: \(newValue)")
        }
    }
    
    private func startBlocking() {
        // Extracting hour and minute components from blockStart and blockEnd
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: blockStart)
        let endComponents = calendar.dateComponents([.hour, .minute], from: blockEnd)
        
        // Extracting hour and minute from components
        let startHour = startComponents.hour ?? 0
        let startMinute = startComponents.minute ?? 0
        let endHour = endComponents.hour ?? 0
        let endMinute = endComponents.minute ?? 0
        
        if endHour <= startHour {
            if endMinute <= startMinute {
                // Add code to validate here (add a banner)
            }
        }
        
        // Call startBlockingTimer with extracted values
        appBlocker.startBlockingTimer(
            blockStartHour: startHour,
            blockEndHour: endHour,
            blockStartMinute: startMinute,
            blockEndMinute: endMinute
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

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
