// TCPTests.swift
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

class TCPTests: XCTestCase {
    func testTCPClientServer() {
        func client(port: Int) {
            do {
                let ip = try IP(address: "127.0.0.1", port: port)
                let clientSocket = try TCPClientSocket(ip: ip)

                let fileDescriptor = try clientSocket.detach()
                XCTAssert(fileDescriptor != -1)
                try clientSocket.attach(fileDescriptor)

                nap(100 * millisecond)

                let data = try clientSocket.receiveString(bufferSize: 3)
                XCTAssert(data == "ABC")

                try clientSocket.sendString("123\n45\n6789")
                try clientSocket.flush()

                clientSocket.close()
            } catch {
                print(error)
                XCTAssert(false)
            }
        }

        do {
            let ip = try IP(port: 5555)
            let serverSocket = try TCPServerSocket(ip: ip)

            let fileDescriptor = try serverSocket.detach()
            XCTAssert(fileDescriptor != -1)
            try serverSocket.attach(fileDescriptor)
            XCTAssert(serverSocket.port == 5555)

            co(client(5555))

            let clientSocket = try serverSocket.accept()
            let deadline = now + 30 * millisecond

            do {
                try clientSocket.receive(bufferSize: 16, deadline: deadline)
                XCTAssert(false)
            } catch {
                XCTAssert(true)
            }

            let diff = now - deadline
            XCTAssert(diff > -300 && diff < 300)

            try clientSocket.sendString("ABC")
            try clientSocket.flush()

            let first = try clientSocket.receiveString(untilDelimiter: "\n")
            XCTAssert(first == "123\n")

            let second = try clientSocket.receiveString(untilDelimiter: "\n")
            XCTAssert(second == "45\n")

            do {
                try clientSocket.receiveString(bufferSize: 3, untilDelimiter: "\n")
                XCTAssert(false)
            } catch TCPError.NoBufferSpaceAvailabe(_, let receivedData) {
                XCTAssert(receivedData.count == 3)
            }

            serverSocket.close()
            clientSocket.close()
        } catch {
            print(error)
            XCTAssert(false)
        }
    }
}

