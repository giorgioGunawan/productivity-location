//
//  SwiftUIView.swift
//  ScreenTimeAPIExample
//
//  Created by Doyeon on 2023/04/25.
//

import SwiftUI

struct SwiftUIView: View {
    
    @EnvironmentObject var model: BlockingApplicationModel
    @State var isPresented = false
    
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
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
