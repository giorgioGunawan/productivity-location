import SwiftUI
import FamilyControls

struct AddScheduleView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var model: BlockingApplicationModel
    @State private var startHour = 9
    @State private var startMinute = 0
    @State private var endHour = 17
    @State private var endMinute = 0
    @State private var name = "New Schedule"
    @State private var selection = FamilyActivitySelection()
    @State private var showingAppsPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Schedule Details")) {
                    TextField("Schedule Name", text: $name)
                    
                    Button(action: {
                        showingAppsPicker = true
                    }) {
                        HStack {
                            Text("Select Apps")
                            Spacer()
                            Text("\(selection.applicationTokens.count) selected")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // ... existing time pickers ...
                }
            }
            .navigationTitle("Add Schedule")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    let newSchedule = BlockSchedule(
                        startHour: startHour,
                        startMinute: startMinute,
                        endHour: endHour,
                        endMinute: endMinute,
                        name: name,
                        selectedApps: selection.applicationTokens
                    )
                    model.schedules.append(newSchedule)
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingAppsPicker) {
                FamilyActivityPicker(selection: $selection)
            }
        }
    }
} 