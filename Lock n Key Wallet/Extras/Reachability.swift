//
//  Reachability.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 12/7/21.
//

import Network

public class Reachability {
    class func isConnectedToNetwork() -> Bool {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "Reachability.Monitor")
        let semaphore = DispatchSemaphore(value: 0)
        var isReachable = false
        
        monitor.pathUpdateHandler = { path in
            isReachable = (path.status == .satisfied)
            semaphore.signal()
            monitor.cancel()
        }
        
        monitor.start(queue: queue)
        _ = semaphore.wait(timeout: .now() + 1.0)
        return isReachable
    }
}
