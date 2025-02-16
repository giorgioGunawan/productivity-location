import SwiftUI
import FamilyControls

struct ScheduleDetailView: View {
    @Binding var schedule: BlockSchedule
    @Environment(\.presentationMode) var presentationMode
    @State private var selection: FamilyActivitySelection
    @State private var showingAppsPicker = false
    @State private var name: String
    
    init(schedule: Binding<BlockSchedule>) {
        self._schedule = schedule
        self._selection = State(initialValue: FamilyActivitySelection(including: schedule.wrappedValue.selectedApps))
        self._name = State(initialValue: schedule.wrappedValue.name)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Schedule Details")) {
                TextField("Schedule Name", text: $name)
                    .onChange(of: name) { newValue in
                        schedule.name = newValue
                    }
                
                Button(action: {
                    showingAppsPicker = true
                }) {
                    HStack {
                        Text("Select Apps")
                        Spacer()
                        Text("\(schedule.selectedApps.count) selected")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // ... other schedule details (time picker, etc.) ...
        }
        .navigationTitle("Edit Schedule")
        .sheet(isPresented: $showingAppsPicker) {
            FamilyActivityPicker(selection: $selection)
                .onChange(of: selection) { newValue in
                    schedule.selectedApps = newValue.applicationTokens
                }
        }
    }
} 