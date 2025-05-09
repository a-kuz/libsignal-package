//
// Copyright 2024 Signal Messenger, LLC.
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import SignalFfi

/// A type-erased version of Completer
private class CompleterBase {
#if compiler(>=6.0)
    typealias RawCompletion = @Sendable (_ error: SignalFfiErrorRef?, _ valuePtr: sending UnsafeRawPointer?) -> Void
#else
    typealias RawCompletion = @Sendable (_ error: SignalFfiErrorRef?, _ valuePtr: UnsafeRawPointer?) -> Void
#endif

    let completeUnsafe: RawCompletion

    init(completeUnsafe: @escaping RawCompletion) {
        self.completeUnsafe = completeUnsafe
    }
}

/// Completer for working with checked continuation
private class Completer<Promise: PromiseStruct>: CompleterBase {
    init(continuation: CheckedContinuation<Promise.Result, Error>) {
        super.init { error, valuePtr in
            do {
                try checkError(error)
                guard let valuePtr else {
                    throw SignalError.internalError("produced neither an error nor a value")
                }
                let value = valuePtr.load(as: Promise.Result.self)
                continuation.resume(returning: value)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func makePromiseStruct() -> Promise {
#if compiler(>=6.0)
        typealias RawPromiseCallback = @convention(c) (_ error: SignalFfiErrorRef?, _ value: sending UnsafeRawPointer?, _ context: UnsafeRawPointer?) -> Void
#else
        typealias RawPromiseCallback = @convention(c) (_ error: SignalFfiErrorRef?, _ value: UnsafeRawPointer?, _ context: UnsafeRawPointer?) -> Void
#endif
        let completeOpaque: RawPromiseCallback = { error, value, context in
            let completer: CompleterBase = Unmanaged.fromOpaque(context!).takeRetainedValue()
            completer.completeUnsafe(error, value)
        }
        
        typealias RawPointerPromiseCallback = @convention(c) (_ error: SignalFfiErrorRef?, _ value: UnsafePointer<UnsafeRawPointer?>?, _ context: UnsafeRawPointer?) -> Void
        let rawPromiseStruct = SignalCPromiseRawPointer(complete: unsafeBitCast(completeOpaque, to: RawPointerPromiseCallback.self), context: Unmanaged.passRetained(self).toOpaque(), cancellation_id: 0)
        
        precondition(MemoryLayout<SignalCPromiseRawPointer>.size == MemoryLayout<Promise>.size)
        return unsafeBitCast(rawPromiseStruct, to: Promise.self)
    }
    
    func cleanUpUncompletedPromiseStruct(_ promiseStruct: Promise) {
        Unmanaged<CompleterBase>.fromOpaque(promiseStruct.context!).release()
    }
}

internal class TokioAsyncContext: NativeHandleOwner<SignalMutPointerTokioAsyncContext>, @unchecked Sendable {
    convenience init() {
        var handle = SignalMutPointerTokioAsyncContext()
        failOnError(signal_tokio_async_context_new(&handle))
        self.init(owned: NonNull(handle)!)
    }

    override internal class func destroyNativeHandle(_ handle: NonNull<SignalMutPointerTokioAsyncContext>) -> SignalFfiErrorRef? {
        signal_tokio_async_context_destroy(handle.pointer)
    }

    /// A thread-safe helper for translating Swift task cancellations into calls to
    /// `signal_tokio_async_context_cancel`.
    private final class CancellationHandoffHelper: @unchecked Sendable {
        // We'd like to remove the `@unchecked` above but Swift 5.10 still complains about
        // 'state' being mutable despite `nonisolated(unsafe)`.
        enum State {
            case initial
            case started(SignalCancellationId)
            case cancelled
        }

        // Emulates Rust's `Mutex<State>` (and the containing class is providing an `Arc`)
        // Unfortunately, doing this in Swift requires a separate allocation for the lock today.
        nonisolated(unsafe) var state: State = .initial
        let lock = NSLock()

        let context: TokioAsyncContext

        init(context: TokioAsyncContext) {
            self.context = context
        }

        func setCancellationId(_ id: SignalCancellationId) {
            // Ideally we would use NSLock.withLock here, but that's not available on Linux,
            // which we still support for development and CI.
            do {
                self.lock.lock()
                defer { self.lock.unlock() }

                switch self.state {
                case .initial:
                    self.state = .started(id)
                    fallthrough
                case .started(_):
                    return
                case .cancelled:
                    break
                }
            }

            // If we didn't early-exit, we're already cancelled.
            self.cancel(id)
        }

        func cancel() {
            let cancelId: SignalCancellationId
            // Ideally we would use NSLock.withLock here, but that's not available on Linux,
            // which we still support for development and CI.
            do {
                self.lock.lock()
                defer { self.lock.unlock() }

                defer { state = .cancelled }
                switch self.state {
                case .started(let id):
                    cancelId = id
                case .initial, .cancelled:
                    return
                }
            }

            // If we didn't early-exit, the task has already started and we need to cancel it.
            self.cancel(cancelId)
        }

        func cancel(_ id: SignalCancellationId) {
            do {
                try self.context.withNativeHandle {
                    try checkError(signal_tokio_async_context_cancel($0.const(), id))
                }
            } catch {
                LoggerBridge.shared?.logger.log(level: .warn, file: #fileID, line: #line, message: "failed to cancel libsignal task \(id): \(error)")
            }
        }
    }

    /// Provides a callback and context for calling Promise-based libsignal\_ffi functions, with cancellation supported.
    ///
    /// Example:
    ///
    /// ```
    /// let result = try await asyncContext.invokeAsyncFunction { promise, runtime in
    ///   signal_do_async_work(promise, runtime, someInput, someOtherInput)
    /// }
    /// ```
    internal func invokeAsyncFunction<Promise: PromiseStruct>(
        _ body: (UnsafeMutablePointer<Promise>, SignalMutPointerTokioAsyncContext) -> SignalFfiErrorRef?
    ) async throws -> Promise.Result {
        let cancellationHelper = CancellationHandoffHelper(context: self)
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
                let completer = Completer<Promise>(continuation: continuation)
                var promiseStruct = completer.makePromiseStruct()
                let startResult = withNativeHandle { handle in
                    body(&promiseStruct, handle)
                }
                if let error = startResult {
                    // Our completion callback is never going to get called, so we need to balance the `passRetained` above.
                    completer.cleanUpUncompletedPromiseStruct(promiseStruct)
                    completer.completeUnsafe(error, nil)
                    return
                }
                cancellationHelper.setCancellationId(promiseStruct.cancellation_id)
            }
        }, onCancel: {
            cancellationHelper.cancel()
        })
    }
}

extension SignalMutPointerTokioAsyncContext: SignalMutPointer {
    public typealias ConstPointer = SignalConstPointerTokioAsyncContext

    public init(untyped: OpaquePointer?) {
        self.init(raw: untyped)
    }

    public func toOpaque() -> OpaquePointer? {
        self.raw
    }

    public func const() -> Self.ConstPointer {
        Self.ConstPointer(raw: self.raw)
    }
}

extension SignalConstPointerTokioAsyncContext: SignalConstPointer {
    public func toOpaque() -> OpaquePointer? {
        self.raw
    }
}
