//
//  MNVaporScheduler.swift
//  
//
//  Created by Ido on 11/06/2023.
//
/*
import Foundation
import Vapor
import DSLogger
import MNUtils
import NIO

fileprivate let dlog : DSLogger? = DLog.forClass("MNVaporScheduler")

class MNVaporTimedTask { // MNTimedTask
    
    
    // MARK: Const
    // MARK: Static
    // MARK: Properties / members
    weak var eventLoopGroup : EventLoopGroup!
    
    // MARK: Private
    private func nextEventLoop() throws ->EventLoop {
        return self.eventLoopGroup.next()
    }
    
    // MARK: Lifecycle
    public init(group:EventLoopGroup) {
        eventLoopGroup = group
    }
    
    // MARK: MNTimedTask
//    func scheduleTask<TResult>(delayFromNow: TimeInterval, task: @Sendable @escaping () throws -> TResult) async -> MNResult<TResult> {
//        do {
//            let sched = try self.nextEventLoop().scheduleTask(deadline: NIODeadline.delayFromNow(delayFromNow), task)
//            return await try .success(sched.futureResult.get())
//        } catch let error {
//            return .failure(code: .misc_concurrency, reason:"scheduleTask \(TResult.self)", underlyingError:error)
//        }
//    }
    
    
    func waitForTask<TResult>(interval: TimeInterval, timeout: TimeInterval, stop: (() -> Bool)?, task: @escaping (WaitResult) throws -> TResult) async -> MNResult<TResult> {
        //
    }
    
    func repeatTask<TResult>(delayFromNow: TimeInterval, interval: TimeInterval, timeout: TimeInterval?, stop: ((Int, TimeInterval) -> Bool)?, task: @escaping () throws -> TResult) async -> TResult {
        //
    }
    
    func debounceTask<TResult>(key: String, threshold: TimeInterval, task: @escaping () async throws -> TResult) -> MNResult<TResult> {
        //
    }
    
    func holdTasksAndBulk<TResult>(key: String, for: TimeInterval, task: @escaping () async throws -> TResult) -> Result<TResult, MNError> {
        //
    }
    
    func accumItems<TResult>(key: String, for: TimeInterval, accum: TResult, stop: (() -> Bool)?) async -> [TResult] {
        //
    }
    
    func accumItems<TResult>(for: TimeInterval, accums: [TResult], stop: (() -> Bool)?) async -> [TResult] {
        //
    }
    
    func accumUniqueItems<TResult>(for: TimeInterval, accums: [TResult], stop: (() -> Bool)?) async -> [TResult] where TResult : Equatable {
        //
    }
    
    // MARK: Public
    
//    @discardableResult
//    func timedTask<T>(deadline: NIODeadline, _ task: @escaping () throws -> T)->NIO.Scheduled<T> {
//        do {
//            return try self.nextEventLoop().scheduleTask(deadline: deadline, task)
//        } catch let error {
//            do {
//                let promise : EventLoopPromise<T> = try self.nextEventLoop().makePromise()
//                let sched = Scheduled(promise: promise) {
//                    dlog?.warning("scheduleTask<T>(deadline: was canceled!")
//                }
//                promise.fail(error)
//                return sched
//            } catch {
//                dlog?.warning("scheduleTask<T>(deadline:) failed creaing a schedulaed task!")
//            }
//        }
//
//        preconditionFailure("scheduleTask<T>(deadline:) failed creaing a schedulaed task!")
//    }

//    @discardableResult
//    public func timedTask<T>(delayFromNow: TimeInterval, _ task: @escaping () throws -> T)->NIO.Scheduled<T> {
//        let deadline = NIODeadline.delayFromNow(delayFromNow)
//        return self.timedTask(deadline: deadline, task)
//    }
//
//    @discardableResult
//    public func timedTask<T>(date: Date, _ task: @escaping () throws -> T)->NIO.Scheduled<T> {
//        guard date.isInTheFuture else {
//            return
//        }
//        let time = abs(date.timeIntervalSinceNow)
//        let deadline = NIODeadline.delayFromNow(delayFromNow)
//        return self.timedTask(deadline: deadline, task)
//    }
     
}
*/
