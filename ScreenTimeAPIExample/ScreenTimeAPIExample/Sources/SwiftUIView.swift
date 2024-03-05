import SwiftUI
import CoreLocation

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    var model: BlockingApplicationModel
    
    init(model: BlockingApplicationModel) {
        self.model = model
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            model.latitude = location.coordinate.latitude
            model.longitude = location.coordinate.longitude
        }
    }
}

struct SwiftUIView: View {
    
    @EnvironmentObject var model: BlockingApplicationModel
    @State private var isPresented = false
    @State private var locationManager = CLLocationManager()
    @State private var locationManagerDelegate: LocationManagerDelegate?
    
    var body: some View {
        VStack {
            Button(action: { isPresented.toggle() }) {
                Text("Check the list of blocked apps")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .familyActivityPicker(isPresented: $isPresented, selection: $model.newSelection)
            
            Spacer()
            
            VStack {
                Text("Latitude: \(model.latitude)")
                Text("Longitude: \(model.longitude)")
            }
        }
        .onAppear {
            locationManagerDelegate = LocationManagerDelegate(model: model)
            locationManager.delegate = locationManagerDelegate
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
            .environmentObject(BlockingApplicationModel())
    }
}
