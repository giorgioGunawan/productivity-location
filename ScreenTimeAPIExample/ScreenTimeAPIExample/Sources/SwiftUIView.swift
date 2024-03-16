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
    
    var body: some View {
        DismissKeyboardWrapper {
            VStack {
                Button(action: { isPresented.toggle() }) {
                    Text("Check the list of blocked apps")
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        )
                        .font(.system(size: 18, weight: .bold))
                        .cornerRadius(8)
                }
                .familyActivityPicker(isPresented: $isPresented, selection: $model.newSelection)
                
                VStack {
                    HStack {
                        Text("Start:")
                        TextField("HH", text: $blockStartHourText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 50) // Adjust the width as needed
                        Text(":")
                        TextField("MM", text: $blockStartMinuteText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 50) // Adjust the width as needed
                    }
                    HStack {
                        Text("End:")
                        TextField("HH", text: $blockEndHourText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 50) // Adjust the width as needed
                        Text(":")
                        TextField("MM", text: $blockEndMinuteText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 50) // Adjust the width as needed
                    }
                    // Button to start blocking
                    Button(action: { startBlocking() }) {
                        Text("Start Blocking")
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
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
                                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                            )
                            .font(.system(size: 18, weight: .bold))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
    }
    
    // Function to start blocking with user-defined times
    private func startBlocking() {
        print("Start Blocking")
        print(blockStartHourText)
        print(blockStartMinuteText)
        print(blockEndHourText)
        print(blockEndMinuteText)
        if let startHour = Int(blockStartHourText),
           let startMinute = Int(blockStartMinuteText),
           let endHour = Int(blockEndHourText),
           let endMinute = Int(blockEndMinuteText) {
            appBlocker.startBlockingTimer(
                blockStartHour: startHour,
                blockEndHour: endHour,
                blockStartMinute: startMinute,
                blockEndMinute: endMinute
            )
        }
    }
    
    private func unblockAll() {
        appBlocker.unblockAllApps();
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
