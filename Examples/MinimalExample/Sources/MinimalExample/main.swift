import Foundation
import LibSignalClient

print("LibSignalClient Demonstration\n")

// Initialize the client
let initialized = LibSignalClient.shared.initialize()
print("Client initialization: \(initialized)")
print("Version: \(LibSignalClient.shared.version)")

// Generate keys for Alice
print("\n--- Generating keys for Alice ---")
let aliceIdentityKeyPair = LibSignalClient.IdentityKeyPair.generate()
let aliceRegistrationId = LibSignalClient.RegistrationId.generate()
let aliceAddress = LibSignalClient.Address(name: "alice@example.org")
let alicePreKeys = LibSignalClient.PreKeyRecord.generatePreKeys(start: 1, count: 10)
let aliceSignedPreKey = LibSignalClient.SignedPreKeyRecord.generate(id: 1, keyPair: aliceIdentityKeyPair)

print("Alice's registration ID: \(aliceRegistrationId.value)")
print("Identity public key: \(aliceIdentityKeyPair.publicKey.hexDescription)")
print("Generated pre-keys: \(alicePreKeys.count)")
print("Signed pre-key ID: \(aliceSignedPreKey.id)")

// Generate keys for Bob
print("\n--- Generating keys for Bob ---")
let bobIdentityKeyPair = LibSignalClient.IdentityKeyPair.generate()
let bobRegistrationId = LibSignalClient.RegistrationId.generate()
let bobAddress = LibSignalClient.Address(name: "bob@example.org")
let bobPreKeys = LibSignalClient.PreKeyRecord.generatePreKeys(start: 1, count: 10)
let bobSignedPreKey = LibSignalClient.SignedPreKeyRecord.generate(id: 1, keyPair: bobIdentityKeyPair)

print("Bob's registration ID: \(bobRegistrationId.value)")
print("Identity public key: \(bobIdentityKeyPair.publicKey.hexDescription)")
print("Generated pre-keys: \(bobPreKeys.count)")
print("Signed pre-key ID: \(bobSignedPreKey.id)")

// Create a pre-key bundle from Bob (which Alice will use)
print("\n--- Creating Bob's pre-key bundle ---")
let bobPreKey = bobPreKeys[0]
let bobBundle = LibSignalClient.PreKeyBundle(
    registrationId: bobRegistrationId.value,
    deviceId: bobAddress.deviceId,
    preKeyId: bobPreKey.id,
    preKeyPublic: bobPreKey.publicKey,
    signedPreKeyId: bobSignedPreKey.id,
    signedPreKeyPublic: bobSignedPreKey.publicKey,
    signedPreKeySignature: bobSignedPreKey.signature,
    identityKey: bobIdentityKeyPair.publicKey
)

// Alice establishes a session with Bob
print("\n--- Alice establishes a session with Bob ---")
let aliceToBobCipher = LibSignalClient.SessionCipher(address: bobAddress)
do {
    try aliceToBobCipher.processPreKeyBundle(bobBundle)
    print("Session successfully established")
} catch {
    print("Session establishment error: \(error)")
}

// Alice encrypts a message for Bob
print("\n--- Alice encrypts a message for Bob ---")
let aliceMessage = "Hello Bob! This is a secret message from Alice.".data(using: .utf8)!
do {
    let encryptedMessage = try aliceToBobCipher.encrypt(aliceMessage)
    print("Message type: \(encryptedMessage.type)")
    print("Encrypted text (\(encryptedMessage.body.count) bytes): \(encryptedMessage.body.hexDescription)")
    
    // Bob decrypts the message from Alice
    print("\n--- Bob decrypts the message from Alice ---")
    let bobFromAliceCipher = LibSignalClient.SessionCipher(address: aliceAddress)
    let decryptedMessage = try bobFromAliceCipher.decrypt(encryptedMessage)
    
    if let decryptedText = String(data: decryptedMessage, encoding: .utf8) {
        print("Decrypted text: \(decryptedText)")
    } else {
        print("Decrypted data (\(decryptedMessage.count) bytes): \(decryptedMessage.hexDescription)")
        print("Note: In this example, data is randomly generated, so the decrypted text won't match the original.")
    }
} catch {
    print("Encryption/decryption error: \(error)")
}

// Extension for convenient binary data display
extension Data {
    var hexDescription: String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
} 