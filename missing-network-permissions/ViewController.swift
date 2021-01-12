import UIKit
import NetworkExtension

class ViewController: UIViewController, SimplePingDelegate {
    
    @IBOutlet weak var infoDeviceLabel: UILabel!
    var pinger: SimplePing?
    var sendTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(foregrounding), name: UIApplication.willEnterForegroundNotification, object: nil)
     }
    
  
    
    @objc func foregrounding() {
        updateDisplayText(msg:"Ping has not been sent yet", msgColor: UIColor.black)
    }
    
    
    @IBAction func pingSelf(_ sender: Any) {
        
        guard let myIp = getWiFiAddress(), !myIp.isEmpty else {
            updateDisplayText(msg:"Unable to retrieve device IP address", msgColor: UIColor.red)
            return // or break, continue, throw
        }
        
        updateDisplayText(msg:"Sending Ping request to: " + myIp, msgColor: UIColor.black)

        let pinger = SimplePing(hostName: myIp)
        self.pinger = pinger
        pinger.delegate = self
        pinger.start()
    }
    
    // Return IP address of WiFi interface (en0) as a String, or `nil`
    func getWiFiAddress() -> String? {
        var address : String?

        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" {

                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)

        return address
    }
    
    func updateDisplayText(msg: String, msgColor: UIColor){
        infoDeviceLabel.text = msg
        infoDeviceLabel.textColor = msgColor
    }
    
    
    func simplePing(_ pinger: SimplePing, didStartWithAddress address: Data) {
        
        updateDisplayText(msg:"pinging...", msgColor: UIColor.black)
        self.pinger!.send(with: nil)
            
        
    }
    
    func simplePing(_ pinger: SimplePing, didFailWithError error: Error) {
        NSLog("failed: %@", error.localizedDescription)
        updateDisplayText(msg:"Failed to ping...", msgColor: UIColor.red)
        self.pinger?.stop()
        self.pinger = nil
    }
    
    var sentTime: TimeInterval = 0
    func simplePing(_ pinger: SimplePing, didSendPacket packet: Data, sequenceNumber: UInt16) {
        sentTime = Date().timeIntervalSince1970
        updateDisplayText(msg:"packet sent: " + String(sequenceNumber), msgColor: UIColor.black)
    }
    
    func simplePing(_ pinger: SimplePing, didFailToSendPacket packet: Data, sequenceNumber: UInt16, error: Error) {
        updateDisplayText(msg:"Failed to send packet", msgColor: UIColor.red)
        self.stop()
    }
    
    func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket packet: Data, sequenceNumber: UInt16) {
        let some = Int(((Date().timeIntervalSince1970 - sentTime).truncatingRemainder(dividingBy: 1)) * 1000)
        print("PING: \(some) MS")
        NSLog("#%u received, size=%zu", sequenceNumber, packet.count)
        
        updateDisplayText(msg:"Received ping request!!", msgColor: UIColor.green)
        self.stop()
    }
    
    func simplePing(_ pinger: SimplePing, didReceiveUnexpectedPacket packet: Data) {
        updateDisplayText(msg:"Received unexpected packet", msgColor: UIColor.yellow)
    }
    
    func stop(){
        self.pinger?.stop()
        self.pinger = nil
    }
}

