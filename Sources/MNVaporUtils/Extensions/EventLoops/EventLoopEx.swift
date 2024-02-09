//
//  File.swift
//  
//
//  Created by Ido on 12/06/2023.
//

import NIO
import Foundation

extension EventLoop {
    /// Schedule a `task` that is executed by this `EventLoop` after the given amount of time.
    ///
    /// - parameters:
    ///     - task: The synchronous task to run. As with everything that runs on the `EventLoop`, it must not block.
    /// - returns: A `Scheduled` object which may be used to cancel the task if it has not yet run, or to wait
    ///            on the completion of the task.
    ///
    /// - note: You can only cancel a task before it has started executing.
    /// - note: The `in` value is clamped to a maximum when running on a Darwin-kernel.
    @discardableResult
    @preconcurrency
    func scheduleTask<T>(in delay: TimeInterval, _ task: @escaping @Sendable () throws -> T) -> Scheduled<T> {
        return self.scheduleTask(deadline: NIODeadline.delayFromNow(delay), task)
    }
}
