// ChannelTests.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import XCTest
import Venice

class ChannelTests: XCTestCase {
    func testReceiverWaitsForSender() {
        let channel = Channel<Int>()
        co {
            yield
            channel <- 333
        }
        XCTAssert(<-channel == 333)
    }

    func testSenderWaitsForReceiver() {
        let channel = Channel<Int>()
        co {
            channel <- 444
        }
        XCTAssert(<-channel == 444)
    }

    func testReceivingChannel() {
        let channel = Channel<Int>()
        func receive(channel: SendingChannel<Int>) {
            channel <- 888
        }
        co(receive(channel.sendingChannel))
        XCTAssert(<-channel == 888)
    }

    func testSendingChannel() {
        let channel = Channel<Int>()
        func send(channel: ReceivingChannel<Int>) {
            XCTAssert(<-channel == 999)
        }
        co{
            channel <- 999
        }
        send(channel.receivingChannel)
    }

    func testTwoSimultaneousSenders() {
        let channel = Channel<Int>()
        co {
            channel <- 888
        }
        co {
            channel <- 999
        }
        XCTAssert(<-channel == 888)
        yield
        XCTAssert(<-channel == 999)
    }

    func testTwoSimultaneousReceivers() {
        let channel = Channel<Int>()
        co {
            XCTAssert(<-channel == 333)
        }
        co {
            XCTAssert(<-channel == 444)
        }
        channel <- 333
        channel <- 444
    }

    func testTypedChannels() {
        let stringChannel = Channel<String>()
        co {
            stringChannel <- "yo"
        }
        XCTAssert(<-stringChannel == "yo")

        struct Foo { let bar: Int; let baz: Int }

        let fooChannel = Channel<Foo>()
        co {
            fooChannel <- Foo(bar: 555, baz: 222)
        }
        let foo = <-fooChannel
        XCTAssert(foo?.bar == 555 && foo?.baz == 222)
    }

    func testMessageBuffering() {
        let channel = Channel<Int>(bufferSize: 2)
        channel <- 222
        channel <- 333
        XCTAssert(<-channel == 222)
        XCTAssert(<-channel == 333)
        channel <- 444
        XCTAssert(<-channel == 444)
        channel <- 555
        channel <- 666
        XCTAssert(<-channel == 555)
        XCTAssert(<-channel == 666)
    }

    func testSimpleChannelClose() {
        let channel1 = Channel<Int>()
        channel1.close()
        XCTAssert(<-channel1 == nil)
        XCTAssert(<-channel1 == nil)
        XCTAssert(<-channel1 == nil)

        let channel2 = Channel<Int>(bufferSize: 10)
        channel2.close()
        XCTAssert(<-channel2 == nil)
        XCTAssert(<-channel2 == nil)
        XCTAssert(<-channel2 == nil)

        let channel3 = Channel<Int>(bufferSize: 10)
        channel3 <- 999
        channel3.close()
        XCTAssert(<-channel3 == 999)
        XCTAssert(<-channel3 == nil)
        XCTAssert(<-channel3 == nil)

        let channel4 = Channel<Int>(bufferSize: 1)
        channel4 <- 222
        channel4.close()
        XCTAssert(<-channel4 == 222)
        XCTAssert(<-channel4 == nil)
        XCTAssert(<-channel4 == nil)
    }

    func testChannelCloseUnblocks() {
        let channel1 = Channel<Int>()
        let channel2 = Channel<Int>()
        co {
            XCTAssert(<-channel1 == nil)
            channel2 <- 0
        }
        co {
            XCTAssert(<-channel1 == nil)
            channel2 <- 0
        }
        channel1.close()
        XCTAssert(<-channel2 == 0)
        XCTAssert(<-channel2 == 0)
    }

    func testBlockedSenderAndItemInTheChannel() {
        let channel = Channel<Int>(bufferSize: 1)
        channel <- 1
        co {
            channel <- 2
        }
        XCTAssert(<-channel == 1)
        XCTAssert(<-channel == 2)
    }

    func testPanicWhenSendingToChannelDeadlocks() {
        let pid = fork()
        XCTAssert(pid >= 0)
        if pid == 0 {
            alarm(1)
            let channel = Channel<Int>()
            signal(SIGABRT) { _ in
                _exit(0)
            }
            channel <- 42
            XCTFail()
        }
        var exitCode: Int32 = 0
        XCTAssert(waitpid(pid, &exitCode, 0) != 0)
        XCTAssert(exitCode == 0)
    }

    func testPanicWhenReceivingFromChannelDeadlocks() {
        let pid = fork()
        XCTAssert(pid >= 0)
        if pid == 0 {
            alarm(1)
            let channel = Channel<Int>()
            signal(SIGABRT) { _ in
                _exit(0)
            }
            <-channel
            XCTFail()
        }
        var exitCode: Int32 = 0
        XCTAssert(waitpid(pid, &exitCode, 0) != 0)
        XCTAssert(exitCode == 0)
    }

    func testChannelIteration() {
        let channel =  Channel<Int>(bufferSize: 2)
        channel <- 555
        channel <- 555
        channel.close()
        for value in channel {
            XCTAssert(value == 555)
        }
    }

    func testSendingChannelIteration() {
        let channel =  Channel<Int>(bufferSize: 2)
        channel <- 444
        channel <- 444
        func receive(channel: ReceivingChannel<Int>) {
            channel.close()
            for value in channel {
                XCTAssert(value == 444)
            }
        }
        receive(channel.receivingChannel)
    }

}
