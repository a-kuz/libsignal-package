# LibSignalClient Swift Package

This is a Swift Package implementation of the LibSignalClient that provides a robust API for the Signal protocol. This implementation demonstrates how libsignal functionality can be packaged and distributed as a Swift Package.

## Features

This implementation offers:
- Full Signal protocol API structure with proper abstractions
- Key generation (identity, pre-keys, signed pre-keys)
- Session management with pre-key bundles
- Message encryption and decryption
- Storage abstraction for sessions, keys, and identities

## Usage

### Add as a Swift Package dependency

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/libsignal.git", from: "0.23.1")
]
```

Or in Xcode, use File → Add Packages... and enter the repository URL.

### Add to your target

```swift
.target(
    name: "YourTarget",
    dependencies: ["LibSignalClient"]
)
```

### Example: Setting up a session and sending messages

```swift
import LibSignalClient

// Generate keys for Alice
let aliceIdentityKeyPair = LibSignalClient.IdentityKeyPair.generate()
let aliceRegistrationId = LibSignalClient.RegistrationId.generate()
let alicePreKeys = LibSignalClient.PreKeyRecord.generatePreKeys(start: 1, count: 10)
let aliceSignedPreKey = LibSignalClient.SignedPreKeyRecord.generate(id: 1, keyPair: aliceIdentityKeyPair)

// Generate keys for Bob
let bobIdentityKeyPair = LibSignalClient.IdentityKeyPair.generate()
let bobRegistrationId = LibSignalClient.RegistrationId.generate()
let bobAddress = LibSignalClient.Address(name: "bob@example.org")
let bobPreKeys = LibSignalClient.PreKeyRecord.generatePreKeys(start: 1, count: 10)
let bobSignedPreKey = LibSignalClient.SignedPreKeyRecord.generate(id: 1, keyPair: bobIdentityKeyPair)

// Create a pre-key bundle for Bob
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
let aliceToBobCipher = LibSignalClient.SessionCipher(address: bobAddress)
try aliceToBobCipher.processPreKeyBundle(bobBundle)

// Alice encrypts a message for Bob
let plaintextMessage = "Hello Bob! This is a secret message.".data(using: .utf8)!
let encryptedMessage = try aliceToBobCipher.encrypt(plaintextMessage)

// Bob decrypts the message from Alice
let bobFromAliceCipher = LibSignalClient.SessionCipher(address: aliceAddress)
let decryptedMessage = try bobFromAliceCipher.decrypt(encryptedMessage)
let messageString = String(data: decryptedMessage, encoding: .utf8)
```

## Example App

Check out the `Examples/MinimalExample` directory for a complete example of using this package for:
- Key generation
- Session establishment
- Message encryption and decryption

## Implementation Details

### Cryptographic Primitives
- Identity key pairs (Curve25519/Ed25519)
- Pre-keys and signed pre-keys
- Message encryption (AES-256-CBC with HMAC-SHA256)

### Signal Protocol
- Pre-key bundles for session establishment
- SessionCipher for message encryption/decryption
- Various message types (whisper, pre-key, etc.)

### Storage
Abstractions for:
- Session storage
- Identity key storage
- Pre-key storage
- Signed pre-key storage

## Next Steps for a Complete Implementation

To create a fully functional Signal protocol library as a Swift Package:

1. Build the Rust FFI layer for all target platforms (iOS, macOS, etc.)
2. Connect the Swift API with the Rust implementation via FFI
3. Implement proper cryptographic functions by calling into libsignal
4. Add error handling and serialization/deserialization

For more details on the full implementation, see the main libsignal repository. 