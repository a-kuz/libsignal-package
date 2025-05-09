import Foundation
import LibSignalClient

print("LibSignalClient Demo")

// Create an instance of LibSignalClient
let client = LibSignalClient.shared
print("Created LibSignalClient instance")

// Generate a key pair
do {
    let keyPair = try IdentityKeyPair.generate()
    print("Generated IdentityKeyPair")
    print("Public key: \(keyPair.publicKey.serialize().map { String(format: "%02X", $0) }.joined())")
} catch {
    print("Error generating key pair: \(error)")
}

// Done
print("Demo completed successfully") 