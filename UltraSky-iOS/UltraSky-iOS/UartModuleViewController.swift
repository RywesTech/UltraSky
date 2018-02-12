//
//  UartModuleViewController.swift
//  UltraSky
//
//  Created by Ryan Westcott and Trevor Beaton.
//

import UIKit
import MapKit
import MessageUI
import CoreLocation
import CoreBluetooth

class UartModuleViewController: UIViewController, CBPeripheralManagerDelegate, UITextViewDelegate, UITextFieldDelegate, CLLocationManagerDelegate, MFMailComposeViewControllerDelegate {
    
    //UI
    @IBOutlet weak var baseTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var switchUI: UISwitch!
    @IBOutlet weak var statusLabel: UILabel!
    
    //Data
    var peripheralManager: CBPeripheralManager?
    var peripheral: CBPeripheral!
    private var consoleAsciiText:NSAttributedString? = NSAttributedString(string: "")
    let locationManager = CLLocationManager()
    
    var log = ""
    var message = ""
    
    var CO2 = 0.0
    var TVOC = 0.0
    var millis = 0
    var temperature = 0.0
    var pressure = 0.0
    var altitude = 0.0
    var lat = 0.0
    var lon = 0.0
    var pm25 = 0.0
    var pm10 = 0.0
    
    var csvLog = "millis,CO2,TVOC,pm25,pm10,temperature,pressure,altitude,lat,lon\n"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Back", style:.plain, target:nil, action:nil)
        self.baseTextView.delegate = self
        self.inputTextField.delegate = self
        //Base text view setup
        self.baseTextView.layer.borderWidth = 3.0
        self.baseTextView.layer.borderColor = UIColor.blue.cgColor
        self.baseTextView.layer.cornerRadius = 3.0
        self.baseTextView.text = ""
        //Input Text Field setup
        self.inputTextField.layer.borderWidth = 2.0
        self.inputTextField.layer.borderColor = UIColor.blue.cgColor
        self.inputTextField.layer.cornerRadius = 3.0
        //Create and start the peripheral manager
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        //-Notification for updating the text view with incoming text
        updateIncomingData()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.baseTextView.text = ""
        
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // peripheralManager?.stopAdvertising()
        // self.peripheralManager = nil
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        
    }
    
    func updateIncomingData () {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "Notify"), object: nil , queue: nil){
            notification in
            let appendString = "\n"
            let myFont = UIFont(name: "Helvetica Neue", size: 15.0)
            let myAttributes2 = [NSAttributedStringKey.font: myFont!, NSAttributedStringKey.foregroundColor: UIColor.red]
            let attribString = NSAttributedString(string: "[Incoming]: " + (characteristicASCIIValue as String) + appendString, attributes: myAttributes2)
            let newAsciiText = NSMutableAttributedString(attributedString: self.consoleAsciiText!)
            self.baseTextView.attributedText = NSAttributedString(string: characteristicASCIIValue as String , attributes: myAttributes2)
            
            newAsciiText.append(attribString)
            
            self.consoleAsciiText = newAsciiText
            //self.baseTextView.attributedText = self.consoleAsciiText
            
            let incomingString = characteristicASCIIValue as String
            
            if incomingString.hasSuffix(";"){
                self.parsePacketString(incomingStr: incomingString)
                // millis,CO2,TVOC,temperature,pressure,altitude,lat,lon
                self.csvLog += "\(self.millis),\(self.CO2),\(self.TVOC),\(self.pm25),\(self.pm10),\(self.temperature),\(self.pressure),\(self.altitude),\(self.lat),\(self.lon)\n"
                
            } else if incomingString.hasSuffix(",") {
                self.parsePacketString(incomingStr: incomingString)
                
            } else {
                print("error")
            }
            
            self.baseTextView.text = self.csvLog + "\n"
            
            self.baseTextView.scrollToBotom()
            
            let secsLeft = (1200000-self.millis)/1000
            if(secsLeft < 0) {
                self.statusLabel.text = "Ready!"
            } else {
                self.statusLabel.text = "Time left for warm up: \(self.secToHMS(seconds: secsLeft).1):\(self.secToHMS(seconds: secsLeft).2)"
            }
        }
    }
    
    func secToHMS (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func parsePacketString(incomingStr: String) {
        var str = incomingStr
        str.remove(at: str.index(before: str.endIndex))
        let strArray = str.characters.split(separator: ":").map(String.init)
        let varName = strArray[0]
        let varValue = strArray[1]
        
        switch varName {
        case "CO2":
            print("CO2")
            CO2 = Double(varValue)!
        case "TVOC":
            print("TVOC")
            TVOC = Double(varValue)!
        case "mil":
            print("millis")
            millis = Int(varValue)!
        case "temp" :
            print("temp")
            temperature = Double(varValue)!
        case "pres":
            print("pres")
            pressure = Double(varValue)!
        case "pm25":
            print("pm25")
            pm25 = Double(varValue)!
        case "pm10":
            print("pm10")
            pm10 = Double(varValue)!
        case "alt" :
            print("alt")
            altitude = Double(varValue)!
        default:
            print("error")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error){
        locationManager.stopUpdatingLocation()
        print("Location Manager Error:")
        print(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue: CLLocationCoordinate2D = manager.location!.coordinate
        lat = locValue.latitude
        lon = locValue.longitude
        print("Got new lat, lon = \(lat), \(lon)")
    }
    
    @IBAction func exportPressed(_ sender: Any) {
        export()
    }
    
    @IBAction func clickSendAction(_ sender: AnyObject) {
        outgoingData()
    }
    
    func outgoingData () {
        let appendString = "\n"
        
        let inputText = inputTextField.text
        
        let myFont = UIFont(name: "Helvetica Neue", size: 15.0)
        let myAttributes1 = [NSAttributedStringKey.font: myFont!, NSAttributedStringKey.foregroundColor: UIColor.blue]
        
        writeValue(data: inputText!)
        
        let attribString = NSAttributedString(string: "[Outgoing]: " + inputText! + appendString, attributes: myAttributes1)
        let newAsciiText = NSMutableAttributedString(attributedString: self.consoleAsciiText!)
        newAsciiText.append(attribString)
        
        consoleAsciiText = newAsciiText
        baseTextView.attributedText = consoleAsciiText
        //erase what's in the text field
        inputTextField.text = ""
        
    }
    
    // Write functions
    func writeValue(data: String){
        let valueString = (data as NSString).data(using: String.Encoding.utf8.rawValue)
        //change the "data" to valueString
        if let blePeripheral = blePeripheral{
            if let txCharacteristic = txCharacteristic {
                blePeripheral.writeValue(valueString!, for: txCharacteristic, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
    
    func writeCharacteristic(val: Int8){
        var val = val
        let ns = NSData(bytes: &val, length: MemoryLayout<Int8>.size)
        blePeripheral!.writeValue(ns as Data, for: txCharacteristic!, type: CBCharacteristicWriteType.withResponse)
    }
    
    func export() {
        
        let fileName = "data.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        let csvText = csvLog
        
        do {
            try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
            
            if MFMailComposeViewController.canSendMail() {
                let emailController = MFMailComposeViewController()
                emailController.mailComposeDelegate = self
                emailController.setToRecipients(["westcottr@go.oes.edu"])
                emailController.setSubject("UltraSky data export")
                emailController.setMessageBody("Hi Ryan,\n\nThe CSV data export is attached.\n\n\nSent from the UltraSky app.", isHTML: false)
                
                do {
                    try emailController.addAttachmentData(NSData(contentsOf: path!) as Data, mimeType: "text/csv", fileName: "data.csv")
                }
                
                present(emailController, animated: true, completion: nil)
            }
            
        } catch {
            
            print("Failed to create file")
            print("\(error)")
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: UITextViewDelegate methods
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if textView === baseTextView {
            //tapping on consoleview dismisses keyboard
            inputTextField.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        scrollView.setContentOffset(CGPoint(x:0, y:250), animated: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        scrollView.setContentOffset(CGPoint(x:0, y:0), animated: true)
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            return
        }
        print("Peripheral manager is running")
    }
    
    //Check when someone subscribe to our characteristic, start sending the data
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Device subscribe to characteristic")
    }
    
    //This on/off switch sends a value of 1 and 0 to the Arduino
    //This can be used as a switch or any thing you'd like
    @IBAction func switchAction(_ sender: Any) {
        if switchUI.isOn {
            print("On ")
            writeCharacteristic(val: 1)
        }
        else
        {
            print("Off")
            writeCharacteristic(val: 0)
            print(writeCharacteristic)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        outgoingData()
        return(true)
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("\(error)")
            return
        }
    }
}

