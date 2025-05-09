import Foundation
import SignalFfi

/// Main client class for Signal Protocol
public class LibSignalClient: @unchecked Sendable {
    /// Shared instance
    public static let shared = LibSignalClient()
    
    /// Private initializer for singleton pattern
    private init() {}
} 