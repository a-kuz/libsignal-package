import Foundation
import LibSignalClient

print("LibSignalClient test")

// Create an instance of LibSignalClient
let client = LibSignalClient.shared
print("Created LibSignalClient instance: \(client)")

// Generate a key pair
let keyPair = try IdentityKeyPair.generate()
print("Generated IdentityKeyPair")
print("Public key: \(keyPair.publicKey.serialize().map { String(format: "%02X", $0) }.joined())")

// Done
print("Test completed successfully") 