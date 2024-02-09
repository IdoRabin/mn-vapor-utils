//
//  MNTimedTask.swift
//  
//
//  Created by Ido on 11/06/2023.
//
/*
import Foundation
import MNUtils

public protocol MNTimedTask {
    
    /// Schedule a task to be performed at a later time
    /// - Parameters:
    ///   - delayFromNow: delay from now in seconds until the time the task will be executed
    ///   - task: task to preform
    /// - Returns: Result of the generic type or error
//    func scheduleTask<TResult>(delayFromNow: TimeInterval, task: @Sendable @escaping () throws -> TResult) async -> MNResult<TResult>
    
    
    /// Wait for a given time until a timeout occurs. during this time, in a given interval check for the stop condition. If the stop condition is true, then perform the task with a .success wair result. otherwise, when timeout is called, perform the task with a .timeout result
    /// - Parameters:
    ///   - interval:interval between stop comdition checks. NOTE: interval must be smaller than timeout.
    ///   - timeout: timeout for completing the task
    ///   - stop: stop condition
    ///   - task: task to perform when stop condition is met OR when timeout occurs (WaitResult will indicate which of the two occured)
    /// - Returns: Result of the generic type or error
    func waitForTask<TResult>(interval: TimeInterval, timeout:TimeInterval, stop:(()->Bool)?, task: @escaping (WaitResult) throws -> TResult) async ->  MNResult<TResult>
    
    
    /// Perfotm a task repetatively for a given amount of time or count of repetitions or when a stop condition is met.
    /// - Parameters:
    ///   - delayFromNow: delay until the first time the task is peformed
    ///   - interval: interval between each performance of the task. NOTE: interval must be smaller than timeout.
    ///   - timeout: timeout to perform the task for the last time. Timeout starts when the first time the task is called.
    ///   - stop:stop condition - will stop the repetition. Even if the task was not performed even once.
    ///   - task: task to perform
    /// - Returns: Result of the generic type or error
    func repeatTask<TResult>(delayFromNow: TimeInterval, interval:TimeInterval, timeout:TimeInterval?, stop:((_ count:Int,_ time:TimeInterval )->Bool)?, task: @escaping () throws -> TResult) async -> TResult
    
    
    /// Will allow a task to be performed once and then will prevent other calls with the same key from being performed for the given time interval threshold.
    ///  NOTE: The tasks / calls made during the time threshold will be lost and ignored.
    /// - Parameters:
    ///   - key: a unique string key that can be used from multiple places in the code. For each unique key there is a separate "holdout" timer.
    ///   - threshold: time threshold during which called with a given key are ignored
    ///   - task: Tsk to perform only hen idle or ignore if threshold time has not passed since last performed task. NOTE: The task will be performed immediately when the holdout timer for this key is idle, or ignored if busy.
    /// - Returns: Result of the generic type or error
    func debounceTask<TResult>(key:String, threshold: TimeInterval, task: @escaping () async throws -> TResult) -> MNResult<TResult>
    
    
    /// Hold (accumulate) the tasks being called using the given key into a serial queue, and perform ALL of the tasks at the end of the 'for' interval The countdown starts when the first call is made for a given key when not already holding tasks for that key,
    ///  NOTE: The tasks / calls made during the time threshold will be kept and performed by order at the end of the time interval.
    /// - Parameters:
    ///   - key: a unique string key that can be used from multiple places in the code. For each unique key there is a separate "holdout" timer.
    ///   - for: time after which all tasks of this key will be performed.
    ///   - task: task to perform at the end of the holdout.
    /// - Returns: Result of all the tasks or errors of the tasks that threw
    func holdTasksAndBulk<TResult>(key:String, for: TimeInterval, task: @escaping () async throws -> TResult) -> Result<TResult, MNError>
    
    
    /// Accumulate the items of a a generic type into an array during a given time interval. After the time elapses, returns an array containing all the accumulated items
    /// NOTE: Items are returned by order of addidion. Duplicate / Equal items may appear in the array more than once.
    /// - Parameters:
    ///   - key: a unique string key that can be used from multiple places in the code. For each unique key there is a separate "holdout" timer.
    ///   - for: time to accumulate the items
    ///   - accum: item to add to the accumulated list
    ///   - stop: stop condition - checked after every additions of an item. If returns true, the accumulated array will be returned immediately and not after the required time.
    /// - Returns:array of the accumulated items
    func accumItems<TResult>(key:String, for:TimeInterval, accum:TResult, stop:(()->Bool)?) async -> [TResult]
    
    /// Accumulate the items of arrrays of a generic type into an array during a given time interval. After the time elapses, returns an array containing all the accumulated items
    /// NOTE: Items are returned by order of addidion. Duplicate / Equal items may appear in the array more than once.
    /// - Parameters:
    ///   - key: a unique string key that can be used from multiple places in the code. For each unique key there is a separate "holdout" timer.
    ///   - for: time to accumulate the items
    ///   - accum:items to add to the accumulated list
    ///   - stop: stop condition - checked after every addition of an item. If returns true, the accumulated array will be returned immediately and not after the required time time.
    /// - Returns:array of the accumulated items
    func accumItems<TResult>(for:TimeInterval, accums:[TResult], stop:(()->Bool)?) async ->  [TResult]
    
    /// Accumulate the items of arrrays of an Equatable generic type into an array during a given time interval. After the time elapses, returns an array containing all the (unique) accumulated items, in order of addition.
    /// NOTE: Unique items are added. If the item is already in the accumulated array, will not be added twice. Uses == to test this.
    /// - Parameters:
    ///   - key: a unique string key that can be used from multiple places in the code. For each unique key there is a separate "holdout" timer.
    ///   - for: time to accumulate the items
    ///   - accum:items to add to the accumulated list
    ///   - stop: stop condition - checked after every addition of an item. If returns true, the accumulated array will be returned immediately and not after the required time time.
    /// - Returns:array of the accumulated items
    func accumUniqueItems<TResult:Equatable>(for:TimeInterval, accums:[TResult], stop:(()->Bool)?) async ->  [TResult]
}
*/
