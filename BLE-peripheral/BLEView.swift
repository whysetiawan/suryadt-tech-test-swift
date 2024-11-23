import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PeripheralViewModel()
    
    var body: some View {
        VStack {
            Text("Characteristic UUID: \(colorCharacteristicUUID.uuidString)")
                .font(.body)
                .padding()
            
            Text("Service UUID: \(colorServiceUUID.uuidString)")
                .font(.body)
                .padding()
            
            // Show the background color
            Rectangle()
                .fill(viewModel.backgroundColor)
                .frame(height: 200)
                .padding()
            
            // Button to start/stop advertising
            Button(action: {
                if viewModel.isAdvertising {
                    viewModel.stopAdvertising()
                } else {
                    viewModel.startAdvertising()
                }
            }) {
                Text(viewModel.isAdvertising ? "Stop Broadcasting" : "Start Broadcasting")
                    .font(.title2)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            
            Button(action: {
                viewModel.sendRandomColor()
            }) {
                Text("Send Random Color")
                    .padding()
                    .font(.title2)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            
            // Display success or error messages
            if let successMessage = viewModel.successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
                    .font(.title2)
                    .padding()
            }
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.title2)
                    .padding()
            }
        }
    }
}


#Preview {
    ContentView()
}
