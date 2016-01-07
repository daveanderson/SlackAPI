// MediaType.swift
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

public struct MediaType: CustomStringConvertible {
    public let type: String
    public let parameters: [String: String]

    public init(type: String, parameters: [String: String] = [:]) {
        self.type = type
        self.parameters = parameters
    }

    public var description: String {
        return "\(type);" + parameters.reduce("") { $0 + " \($1.0)=\($1.1)" }
    }

    public init(string: String) {
        let mediaTypeTokens = string.splitBy(";")
        let mediaType = mediaTypeTokens.first!
        var parameters: [String: String] = [:]

        if mediaTypeTokens.count == 2 {
            let parametersTokens = mediaTypeTokens[1].trim().splitBy(" ")

            for parametersToken in parametersTokens {
                let parameterTokens = parametersToken.splitBy("=")

                if parameterTokens.count == 2 {
                    let key = parameterTokens[0]
                    let value = parameterTokens[1]
                    parameters[key] = value
                }
            }
        }

        self.type = mediaType.lowercaseString
        self.parameters = parameters
    }
}

extension MediaType: Hashable {
    public var hashValue: Int {
        return description.hashValue
    }
}

public func ==(lhs: MediaType, rhs: MediaType) -> Bool {
    return lhs.type == rhs.type
}

let JSONMediaType = MediaType(type: "application/json", parameters: ["charset": "utf-8"])
let XMLMediaType = MediaType(type: "application/xml", parameters: ["charset": "utf-8"])
let URLEncodedFormMediaType = MediaType(type: "application/x-www-form-urlencoded")