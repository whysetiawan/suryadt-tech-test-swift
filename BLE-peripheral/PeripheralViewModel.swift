import SwiftUI
import CoreBluetooth

// Global constants for UUIDs
let colorCharacteristicUUID = CBUUID(string: "2A37") // Custom UUID for color characteristic
let colorServiceUUID = CBUUID(string: "180D") // Example service UUID (can be customized)

class PeripheralViewModel: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    
    private var peripheralManager: CBPeripheralManager?
    private var colorCharacteristic: CBMutableCharacteristic?
    private var colorService: CBMutableService?
    
    @Published var isAdvertising = false
    @Published var backgroundColor: Color = .white  // Published background color
    @Published var errorMessage: String? = nil  // For handling error message
    @Published var successMessage: String? = nil  // For handling success message
    
    // Initialize the peripheral manager and set the delegate to self
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    // Generate a random color and return as a hex code
    func generateRandomColorHex() -> String {
        let red = UInt8.random(in: 0...255)
        let green = UInt8.random(in: 0...255)
        let blue = UInt8.random(in: 0...255)
        
        // Convert RGB values to hex
        let hexColor = String(format: "#%02X%02X%02X", red, green, blue)
        
        // Update the background color based on the hex color
        DispatchQueue.main.async {
            self.backgroundColor = Color(
                red: Double(red) / 255.0,
                green: Double(green) / 255.0,
                blue: Double(blue) / 255.0
            )
        }
        
        return hexColor
    }
    
    func hexStringToColor(_ hex: String) -> Color? {
        // Remove the # if present
        var hexString = hex
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        
        // Ensure the string is a valid hex code
        guard hexString.count == 6, let rgbValue = UInt64(hexString, radix: 16) else {
            return nil
        }
        
        let red = Double((rgbValue >> 16) & 0xFF) / 255.0
        let green = Double((rgbValue >> 8) & 0xFF) / 255.0
        let blue = Double(rgbValue & 0xFF) / 255.0
        
        return Color(red: red, green: green, blue: blue)
    }
    
    // Send random hex color to the central
    func sendRandomColorHex() {
        let hexColor = generateRandomColorHex()
        colorCharacteristic?.value = hexColor.data(using: .utf8)  // Convert hex string to Data
        print("Sending hex color data: \(hexColor)")
    }
    
    // Start advertising the peripheral
    func startAdvertising() {
        if peripheralManager?.state == .poweredOn {
            
            // Create the color characteristic with the hex code data (read, notify, write)
            colorCharacteristic = CBMutableCharacteristic(
                type: colorCharacteristicUUID,
                properties: [.read, .notify, .write], // Allow write operations
                value: nil,  // No initial cached value
                permissions: [.readable, .writeable] // Make the characteristic both readable and writable
            )
            
            colorService = CBMutableService(type: colorServiceUUID, primary: true)
            colorService?.characteristics = [colorCharacteristic!]
            
            peripheralManager?.add(colorService!)
            
            peripheralManager?.startAdvertising(
                [
                    CBAdvertisementDataServiceUUIDsKey: [colorServiceUUID],
                    CBAdvertisementDataLocalNameKey : "Wahyu's iPhone",
                ]
            )
            isAdvertising = true
            successMessage = "Advertising started successfully!"  // Success message
            errorMessage = nil
        } else {
            // Advertising failed due to Bluetooth not being available
            errorMessage = "Bluetooth is not powered on. Please enable Bluetooth."
            successMessage = nil
        }
    }
    
    // Stop advertising the peripheral
    func stopAdvertising() {
        peripheralManager?.stopAdvertising()
        isAdvertising = false
        successMessage = nil  // Clear success message when stopping
    }
    
    // Delegate method to handle Bluetooth state changes
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("Peripheral is powered on")
            
        case .poweredOff:
            print("Peripheral is powered off")

        case .resetting:
            print("Peripheral is resetting")
        case .unsupported:
            print("Peripheral is unsupported")

        case .unauthorized:
            print("Peripheral is unauthorized")

        case .unknown:
            print("Peripheral state is unknown")
        @unknown default:
            print("Unknown peripheral state")
        }
    }
    
    // Delegate method to respond to read requests from central devices
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("Someone reading me \(request.characteristic.uuid)")
        if request.characteristic.uuid == colorCharacteristic?.uuid {
            // Send updated hex color value to the central when requested
            request.value = generateRandomColorHex().data(using: .utf8)  // Send hex as Data
            peripheral.respond(to: request, withResult: .success)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        if characteristic.uuid == colorCharacteristic?.uuid {
            print("Central subscribed to characteristic: \(characteristic.uuid)")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        if characteristic.uuid == colorCharacteristic?.uuid {
            print("Central unsubscribed from characteristic: \(characteristic.uuid)")
        }
    }
    
    // Delegate method to handle write requests from the central
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == colorCharacteristic?.uuid {
                // Convert the received data into a string (hex code)
                if let value = request.value, let receivedHexCode = String(data: value, encoding: .utf8) {
                    print("Received hex color code from central: \(receivedHexCode)")
                    
                    // Update the background color based on the received hex code
                    DispatchQueue.main.async {
                        if let color = self.hexStringToColor(receivedHexCode) {
                            self.backgroundColor = color
                        } else {
                            print("Invalid hex color code received")
                        }
                    }
                    // Respond to the central confirming the write
                    peripheral.respond(to: request, withResult: .success)
                }
            }
        }
    }
    
    // Send color notifications to subscribed centrals (streaming)
    func sendRandomColor() {
        guard peripheralManager?.state == .poweredOn else {
            print("Peripheral manager is not powered on.")
            return
        }
        
        guard let colorCharacteristic = colorCharacteristic else {
            print("Color characteristic not initialized.")
            return
        }
        
        let hexColor = generateRandomColorHex()
        guard let hexData = hexColor.data(using: .utf8), hexData.count <= 20 else {
            print("Data exceeds MTU size")
            return
        }
        
        let success = peripheralManager?.updateValue(hexData, for: colorCharacteristic, onSubscribedCentrals: nil) ?? false
        if success {
            print("Notification sent successfully: \(hexColor)")
        } else {
            print("Failed to send notification.")
        }
    }
}
