# iOS Integration Guide

This guide helps you integrate LibSignalClient into your iOS application.

## Requirements

- iOS 13.0+
- Swift 5.9+
- Xcode 15.0+

## Installation Options

### Option 1: Swift Package Manager (Recommended)

1. In Xcode, select File > Add Packages...
2. Enter the repository URL: `https://github.com/yourusername/libsignal-swift.git`
3. Select the version you want to use
4. Click "Add Package"

Swift Package Manager will automatically download and integrate the package into your project.

### Option 2: Manual XCFramework Integration

1. Download the latest `LibSignalClient.xcframework.zip` from the [Releases](https://github.com/yourusername/libsignal-swift/releases) page
2. Unzip the downloaded file
3. Drag the XCFramework into your Xcode project
4. When prompted, make sure "Copy items if needed" is selected
5. Select your target and ensure the framework is added under "Frameworks, Libraries, and Embedded Content"
6. Make sure "Embed & Sign" is selected for the framework

## Basic Usage

Here's a basic example of how to use the library in your Swift code:

```swift
import LibSignalClient

// Initialize the library
func initializeSignal() {
    // Create an instance of LibSignalClient
    let client = LibSignalClient.shared
    
    // Generate a key pair
    do {
        let keyPair = try IdentityKeyPair.generate()
        print("Generated identity key pair")
        
        // Save the key pair for later use
        // ... your code to securely store the key pair
    } catch {
        print("Error generating key pair: \(error)")
    }
}

// Example of creating an address
func createAddress() -> ProtocolAddress? {
    do {
        let deviceId: UInt32 = 1
        let address = try ProtocolAddress(name: "+1234567890", deviceId: deviceId)
        return address
    } catch {
        print("Error creating address: \(error)")
        return nil
    }
}
```

## Advanced Usage

### Session Management

```swift
import LibSignalClient

func createSession(for recipient: ProtocolAddress, preKey: PreKeyBundle) {
    do {
        let sessionStore = InMemorySessionStore()
        let identityStore = InMemoryIdentityKeyStore()
        
        try ProcessContext.withSessionStore(sessionStore) { sessionStore in
            try ProcessContext.withIdentityKeyStore(identityStore) { identityStore in
                try SessionBuilder(for: recipient,
                                   sessionStore: sessionStore,
                                   identityKeyStore: identityStore).processPreKeyBundle(preKey)
                print("Session created successfully")
            }
        }
    } catch {
        print("Error creating session: \(error)")
    }
}
```

### Sending Messages

```swift
func sendMessage(to recipient: ProtocolAddress, message: String) {
    do {
        let sessionStore = InMemorySessionStore()
        let identityStore = InMemoryIdentityKeyStore()
        
        try ProcessContext.withSessionStore(sessionStore) { sessionStore in
            try ProcessContext.withIdentityKeyStore(identityStore) { identityStore in
                let ciphertextMessage = try CiphertextMessage.encrypt(
                    message.data(using: .utf8)!,
                    for: recipient,
                    sessionStore: sessionStore,
                    identityKeyStore: identityStore)
                
                // Send ciphertextMessage over the network
                // ...
            }
        }
    } catch {
        print("Error sending message: \(error)")
    }
}
```

### Receiving Messages

```swift
func receiveMessage(from sender: ProtocolAddress, ciphertext: CiphertextMessage) {
    do {
        let sessionStore = InMemorySessionStore()
        let identityStore = InMemoryIdentityKeyStore()
        
        try ProcessContext.withSessionStore(sessionStore) { sessionStore in
            try ProcessContext.withIdentityKeyStore(identityStore) { identityStore in
                let plaintext = try MessageDecrypter.decrypt(
                    message: ciphertext,
                    from: sender,
                    sessionStore: sessionStore,
                    identityKeyStore: identityStore)
                
                if let messageString = String(data: plaintext, encoding: .utf8) {
                    print("Received message: \(messageString)")
                }
            }
        }
    } catch {
        print("Error receiving message: \(error)")
    }
}
```

## Thread Safety

LibSignalClient is designed to be thread-safe. However, you should ensure that your own code correctly handles concurrent access to shared resources like key stores and session stores.

## Error Handling

The library uses Swift's native error handling mechanism. Most methods can throw exceptions that should be caught and handled appropriately in your application.

## Best Practices

1. Always securely store encryption keys and session information
2. Properly validate user identities before establishing sessions
3. Implement proper error handling for encryption/decryption operations
4. Consider caching session information for better performance
5. Implement key rotation policies based on your security requirements

## Troubleshooting

If you encounter issues with the library integration:

1. Make sure your minimum deployment target is iOS 13.0 or later
2. Check that the library is correctly embedded in your app
3. If using Swift Package Manager, try clearing derived data and reinstalling the package
4. For framework issues, make sure the XCFramework is properly signed and embedded 