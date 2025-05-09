import Foundation
import LibSignalClient

// Simple implementation of protocol stores for the example
class InMemorySignalProtocolStore: IdentityKeyStore, PreKeyStore, SignedPreKeyStore, KyberPreKeyStore, SessionStore, SenderKeyStore {
    private var identityKeyPair: IdentityKeyPair
    private var localRegistrationId: UInt32
    private var identities: [ProtocolAddress: IdentityKey] = [:]
    private var preKeys: [UInt32: PreKeyRecord] = [:]
    private var signedPreKeys: [UInt32: SignedPreKeyRecord] = [:]
    private var kyberPreKeys: [UInt32: KyberPreKeyRecord] = [:]
    private var sessions: [ProtocolAddress: SessionRecord] = [:]
    private var senderKeys: [(sender: ProtocolAddress, distributionId: UUID, record: SenderKeyRecord)] = []
    
    init() {
        // Generate identity key and registration ID
        self.identityKeyPair = IdentityKeyPair.generate()
        
        do {
            self.localRegistrationId = try IdentityKeyPair.generateRegistrationId(extendedRange: false)
        } catch {
            fatalError("Failed to generate registration ID: \(error)")
        }
    }
    
    // MARK: - IdentityKeyStore
    
    func identityKeyPair(context: StoreContext) throws -> IdentityKeyPair {
        return identityKeyPair
    }
    
    func localRegistrationId(context: StoreContext) throws -> UInt32 {
        return localRegistrationId
    }
    
    func saveIdentity(_ identity: IdentityKey, for address: ProtocolAddress, context: StoreContext) throws -> Bool {
        let existingIdentity = identities[address]
        identities[address] = identity
        return existingIdentity != nil
    }
    
    func identity(for address: ProtocolAddress, context: StoreContext) throws -> IdentityKey? {
        return identities[address]
    }
    
    func isTrustedIdentity(_ identity: IdentityKey, for address: ProtocolAddress, direction: IdentityKeyStore.Direction, context: StoreContext) throws -> Bool {
        if let existingIdentity = identities[address] {
            return existingIdentity.publicKey.serialize() == identity.publicKey.serialize()
        }
        // Trust on first use
        return true
    }
    
    func allIdentityKeys(context: StoreContext) throws -> [ProtocolAddress: IdentityKey] {
        return identities
    }
    
    // MARK: - PreKeyStore
    
    func loadPreKey(id: UInt32, context: StoreContext) throws -> PreKeyRecord {
        guard let record = preKeys[id] else {
            throw SignalError.invalidKeyId("No pre key with ID \(id)")
        }
        return record
    }
    
    func storePreKey(_ record: PreKeyRecord, id: UInt32, context: StoreContext) throws {
        preKeys[id] = record
    }
    
    func containsPreKey(id: UInt32, context: StoreContext) throws -> Bool {
        return preKeys[id] != nil
    }
    
    func deletePreKey(id: UInt32, context: StoreContext) throws {
        preKeys.removeValue(forKey: id)
    }
    
    func getAllPreKeyRecords(context: StoreContext) throws -> [PreKeyRecord] {
        return Array(preKeys.values)
    }
    
    // MARK: - SignedPreKeyStore
    
    func loadSignedPreKey(id: UInt32, context: StoreContext) throws -> SignedPreKeyRecord {
        guard let record = signedPreKeys[id] else {
            throw SignalError.invalidKeyId("No signed pre key with ID \(id)")
        }
        return record
    }
    
    func storeSignedPreKey(_ record: SignedPreKeyRecord, id: UInt32, context: StoreContext) throws {
        signedPreKeys[id] = record
    }
    
    func containsSignedPreKey(id: UInt32, context: StoreContext) throws -> Bool {
        return signedPreKeys[id] != nil
    }
    
    func deleteSignedPreKey(id: UInt32, context: StoreContext) throws {
        signedPreKeys.removeValue(forKey: id)
    }
    
    func getAllSignedPreKeyRecords(context: StoreContext) throws -> [SignedPreKeyRecord] {
        return Array(signedPreKeys.values)
    }
    
    // MARK: - KyberPreKeyStore
    
    func loadKyberPreKey(id: UInt32, context: StoreContext) throws -> KyberPreKeyRecord {
        guard let record = kyberPreKeys[id] else {
            throw SignalError.invalidKeyId("No Kyber pre key with ID \(id)")
        }
        return record
    }
    
    func storeKyberPreKey(_ record: KyberPreKeyRecord, id: UInt32, context: StoreContext) throws {
        kyberPreKeys[id] = record
    }
    
    func containsKyberPreKey(id: UInt32, context: StoreContext) throws -> Bool {
        return kyberPreKeys[id] != nil
    }
    
    func deleteKyberPreKey(id: UInt32, context: StoreContext) throws {
        kyberPreKeys.removeValue(forKey: id)
    }
    
    func markKyberPreKeyUsed(id: UInt32, context: StoreContext) throws {
        // In a real implementation, this would mark the key as used
    }
    
    func getAllKyberPreKeyRecords(context: StoreContext) throws -> [KyberPreKeyRecord] {
        return Array(kyberPreKeys.values)
    }
    
    // MARK: - SessionStore
    
    func loadSession(for address: ProtocolAddress, context: StoreContext) throws -> SessionRecord? {
        return sessions[address]
    }
    
    func storeSession(_ record: SessionRecord, for address: ProtocolAddress, context: StoreContext) throws {
        sessions[address] = record
    }
    
    func containsSession(for address: ProtocolAddress, context: StoreContext) throws -> Bool {
        return sessions[address] != nil
    }
    
    func deleteSession(for address: ProtocolAddress, context: StoreContext) throws {
        sessions.removeValue(forKey: address)
    }
    
    func deleteAllSessions(for name: String, context: StoreContext) throws -> Int {
        let initialCount = sessions.count
        sessions = sessions.filter { $0.key.name != name }
        return initialCount - sessions.count
    }
    
    func getAllSessionRecords(context: StoreContext) throws -> [SessionRecord] {
        return Array(sessions.values)
    }
    
    // MARK: - SenderKeyStore
    
    func storeSenderKey(from sender: ProtocolAddress, distributionId: UUID, record: SenderKeyRecord, context: StoreContext) throws {
        // Remove existing record with same sender/distributionId if exists
        senderKeys.removeAll { $0.sender.deviceId == sender.deviceId && $0.sender.name == sender.name && $0.distributionId == distributionId }
        // Add new record
        senderKeys.append((sender: sender, distributionId: distributionId, record: record))
    }
    
    func loadSenderKey(from sender: ProtocolAddress, distributionId: UUID, context: StoreContext) throws -> SenderKeyRecord? {
        return senderKeys.first { 
            $0.sender.deviceId == sender.deviceId && 
            $0.sender.name == sender.name && 
            $0.distributionId == distributionId 
        }?.record
    }
    
    func getAllSenderKeyRecords(context: StoreContext) throws -> [(sender: ProtocolAddress, distributionId: UUID, record: SenderKeyRecord)] {
        return senderKeys
    }
}

// MARK: - Example Function

/// Runs a basic example of the Signal protocol
public func runSignalExample() throws {
    // Set up logging
    setLogLevel(.info)
    setLogger(ConsoleLogger.shared)
    
    print("📱 Starting Signal Protocol Example")
    
    // Create our client instance
    let client = LibSignalClient.shared
    
    // Create protocol store
    let aliceStore = InMemorySignalProtocolStore()
    let bobStore = InMemorySignalProtocolStore()
    
    // Get the identity keys from the stores
    let aliceIdentityKey = try aliceStore.identityKeyPair(context: StoreContext()).identityKey
    let bobIdentityKey = try bobStore.identityKeyPair(context: StoreContext()).identityKey
    
    print("Alice identity key: \(aliceIdentityKey.publicKey.serialize().map { String(format: "%02X", $0) }.joined())")
    print("Bob identity key: \(bobIdentityKey.publicKey.serialize().map { String(format: "%02X", $0) }.joined())")
    
    // Create protocol addresses
    let aliceAddress = try ProtocolAddress(name: "alice", deviceId: 1)
    let bobAddress = try ProtocolAddress(name: "bob", deviceId: 1)
    
    // Generate pre keys for Bob
    let bobPreKeyId: UInt32 = 1
    let bobSignedPreKeyId: UInt32 = 1
    
    let bobPreKeyRecord = try PreKeyRecord(id: bobPreKeyId, privateKey: PrivateKey.generate())
    let bobSignedPreKeyRecord = try SignedPreKeyRecord(
        id: bobSignedPreKeyId,
        timestamp: UInt64(Date().timeIntervalSince1970 * 1000),
        privateKey: PrivateKey.generate(),
        signature: try bobStore.identityKeyPair(context: StoreContext()).privateKey.generateSignature(
            message: try bobPreKeyRecord.publicKey().serialize()
        )
    )
    
    // Store Bob's pre keys in his store
    try bobStore.storePreKey(bobPreKeyRecord, id: bobPreKeyId, context: StoreContext())
    try bobStore.storeSignedPreKey(bobSignedPreKeyRecord, id: bobSignedPreKeyId, context: StoreContext())
    
    // Create a pre key bundle for Bob
    let bobPreKeyBundle = try PreKeyBundle(
        registrationId: try bobStore.localRegistrationId(context: StoreContext()),
        deviceId: bobAddress.deviceId,
        preKeyId: bobPreKeyId,
        preKey: bobPreKeyRecord.publicKey(),
        signedPreKeyId: bobSignedPreKeyId,
        signedPreKey: bobSignedPreKeyRecord.publicKey(),
        signedPreKeySignature: bobSignedPreKeyRecord.signature,
        identity: bobIdentityKey
    )
    
    // Process the pre key bundle for Alice
    try processPreKeyBundle(
        bobPreKeyBundle,
        for: bobAddress,
        sessionStore: aliceStore,
        identityStore: aliceStore,
        context: StoreContext()
    )
    
    print("Alice processed Bob's pre-key bundle - session established")
    
    // Encrypt a message from Alice to Bob
    let originalMessage = "Hello, Signal Protocol!".data(using: .utf8)!
    let aliceToBobMessage = try signalEncrypt(
        message: originalMessage,
        for: bobAddress,
        sessionStore: aliceStore,
        identityStore: aliceStore,
        context: StoreContext()
    )
    
    print("Alice encrypted message for Bob: \(aliceToBobMessage.serialize().count) bytes")
    
    // Decrypt the message on Bob's side
    let receivedMessage: PreKeySignalMessage
    if aliceToBobMessage.messageType == .preKey {
        receivedMessage = try PreKeySignalMessage(bytes: aliceToBobMessage.serialize())
        
        let decryptedMessage = try signalDecryptPreKey(
            message: receivedMessage,
            from: aliceAddress,
            sessionStore: bobStore,
            identityStore: bobStore,
            preKeyStore: bobStore,
            signedPreKeyStore: bobStore,
            kyberPreKeyStore: bobStore,
            context: StoreContext()
        )
        
        // Convert bytes back to string
        if let decryptedString = String(data: Data(decryptedMessage), encoding: .utf8) {
            print("Bob decrypted message from Alice: \"\(decryptedString)\"")
        } else {
            print("Bob decrypted message but couldn't convert to string")
        }
        
        // Now let's have Bob respond to Alice
        let bobResponse = "Nice to meet you, Alice!".data(using: .utf8)!
        let bobToAliceMessage = try signalEncrypt(
            message: bobResponse,
            for: aliceAddress,
            sessionStore: bobStore,
            identityStore: bobStore,
            context: StoreContext()
        )
        
        print("Bob encrypted response for Alice: \(bobToAliceMessage.serialize().count) bytes")
        
        // Alice decrypts Bob's response
        if bobToAliceMessage.messageType == .whisper {
            let bobSignalMessage = try SignalMessage(bytes: bobToAliceMessage.serialize())
            
            let aliceDecryptedMessage = try signalDecrypt(
                message: bobSignalMessage,
                from: bobAddress,
                sessionStore: aliceStore,
                identityStore: aliceStore,
                context: StoreContext()
            )
            
            if let aliceDecryptedString = String(data: Data(aliceDecryptedMessage), encoding: .utf8) {
                print("Alice decrypted response from Bob: \"\(aliceDecryptedString)\"")
            } else {
                print("Alice decrypted response but couldn't convert to string")
            }
        } else {
            print("Unexpected message type from Bob: \(bobToAliceMessage.messageType)")
        }
    } else {
        print("Unexpected message type from Alice: \(aliceToBobMessage.messageType)")
    }
    
    print("📱 Signal Protocol Example Complete")
} 