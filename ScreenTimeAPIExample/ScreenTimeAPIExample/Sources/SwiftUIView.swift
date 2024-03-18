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
    
    @State var stepCount: String = "0" // Add stepCount

    var body: some View {
        DismissKeyboardWrapper {
            VStack {
                
                Button(action: { isPresented.toggle() }) {
                    Text("Apps to Block")
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.black]), startPoint: .leading, endPoint: .trailing))
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        )
                        .font(.system(size: 18, weight: .bold))
                        .cornerRadius(8)
                }
                .familyActivityPicker(isPresented: $isPresented, selection: $model.newSelection)
                VStack {
                    Grid {
                        GridRow {
                            HStack {
                                Text("Start:")
                                DatePicker("", selection: $blockStart, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .datePickerStyle(DefaultDatePickerStyle())
                                    .frame(width: 150)
                            }
                        }
                        Divider().gridCellUnsizedAxes(.horizontal)
                        GridRow {
                            HStack {
                                Text("End:")
                                DatePicker("", selection: $blockEnd, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .datePickerStyle(DefaultDatePickerStyle())
                                    .frame(width: 150)
                            }
                        }
                    }
                    Spacer()
                    HStack {
                        Button(action: { unblockTemp() }) {
                            Text("Unblock 10s")
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.black]), startPoint: .leading, endPoint: .trailing))
                                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                                )
                                .font(.system(size: 18, weight: .bold))
                                .cornerRadius(8)
                        }
                        Text("Steps Count: \(self.stepCount)") // Display step count
                        TextField("Steps Count", text: $stepCount)
                    }
                    HStack {
                        // Button to start blocking
                        Button(action: { startBlocking() }) {
                            Text("Start Blocking")
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.black]), startPoint: .leading, endPoint: .trailing))
                                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                                )
                                .font(.system(size: 18, weight: .bold))
                                .cornerRadius(8)
                        }
                        Button(action: { unblockAll() }) {
                             Text("Unblock All")
                             .foregroundColor(.white)
                             .padding(.vertical, 12)
                             .padding(.horizontal, 24)
                             .background(
                             RoundedRectangle(cornerRadius: 8)
                             .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.black]), startPoint: .leading, endPoint: .trailing))
                             .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                             )
                             .font(.system(size: 18, weight: .bold))
                             .cornerRadius(8)
                         }
                    }
                }
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
        .onReceive(appBlocker.$stepCount.receive(on: DispatchQueue.main)) { count in
            // Update stepCount when received from AppBlocker on the main thread
            
            DispatchQueue.main.asyncAfter(deadline: .now()){
                self.stepCount = String(count)
                print("on receive")
                print(self.stepCount)
            }
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
        appBlocker.unblockAllApps();
    }
    
    private func unblockTemp() {
        appBlocker.unblockTemp();
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
