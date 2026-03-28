//
//  NetworkMonitor.swift
//  video_player
//
//  Network reachability monitoring for player stall recovery.
//  Observes network state changes and notifies interested parties.
//

import Foundation
import Network

/// Monitors network reachability using NWPathMonitor.
/// Used by the player to detect when connectivity is restored
/// so it can attempt stall recovery automatically.
final class NetworkMonitor {
    
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "video.player.network.monitor", qos: .utility)
    
    private(set) var isConnected: Bool = true
    private(set) var connectionType: ConnectionType = .unknown
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    /// Called when network status changes. `isConnected` = true means connectivity restored.
    var onNetworkStatusChange: ((Bool) -> Void)?
    
    private init() {}
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let connected = path.status == .satisfied
            let type = self.connectionType(from: path)
            
            DispatchQueue.main.async {
                let wasConnected = self.isConnected
                self.isConnected = connected
                self.connectionType = type
                
                // Only notify on state change
                if wasConnected != connected {
                    self.onNetworkStatusChange?(connected)
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
        onNetworkStatusChange = nil
    }
    
    private func connectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .ethernet }
        return .unknown
    }
}
