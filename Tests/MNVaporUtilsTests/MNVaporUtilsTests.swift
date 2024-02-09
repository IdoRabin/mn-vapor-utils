import XCTest
import DSLogger
import NIO
import MNUtils
@testable import MNVaporUtils

let dlog : DSLogger? = DLog.forClass("MNVaporUtilsTests")

final class MNVaporUtilsTests: XCTestCase {
    var group: EventLoopGroup!
    /*
    var timed : MNVaporTimedTask!
    
    override func setUp() async throws {
        dlog?.info("setUp")
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: 2)
        self.timed = MNVaporTimedTask(group: group)
    }
    
    override func tearDown() {
        dlog?.info("tearDown")
        do {
            try self.group.syncShutdownGracefully()
        } catch let error {
            dlog?.warning("tearDown failed shutting down ELGroup gracefully with error: \(error.description)")
        }
    }
    
    func testTimedTasks() throws {
        dlog?.info("testTimedTasks")
        var str = "1"
        let promise = expectation(description: "Just wait 5 seconds")
        group.next().scheduleTask(in: 0.2, {
            dlog?.info("Task performed")
            str += "3"
            promise.fulfill()
        })
        dlog?.info("After Task scheduled")
        str += "2"
        
        waitForExpectations(timeout: 5) { (error) in
            XCTAssert(str == "123", "Order of events not as expected! (\(str))")
            dlog?.info("waitForExpectations done \(str)")
        }
    }
     */

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        // XCTAssertEqual(MNVaporUtils().text, "Hello, World!")
    }
}
