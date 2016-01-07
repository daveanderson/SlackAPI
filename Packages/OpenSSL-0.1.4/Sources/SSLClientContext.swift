// SSLClientContext.swift
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
// IMPLIED, INCLUDINbG BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Core
import COpenSSL

public final class SSLClientContext: SSLContext, SSLClientContextType {

	public var streamType: SSLClientStreamType.Type {
		return SSLClientStream.self
	}

	public init() {
		super.init(method: .SSLv23, type: .Client)

		self.withContext { ctx in
			//SSL_CTX_set_verify(ctx, SSL_VERIFY_NONE, nil)
			SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER) { preverify, x509_ctx -> Int32 in
				print("verify | preverify = \(preverify) | x509_ctx = \(x509_ctx)")
				return preverify
			}
			SSL_CTX_set_verify_depth(ctx, 4)
			SSL_CTX_set_options(ctx, SSL_OP_NO_SSLv2 | SSL_OP_NO_SSLv3 | SSL_OP_NO_COMPRESSION)
            #if os(OSX)
            let certificateLocations = "/usr/local/etc/openssl/cert.pem"
            #else
            let certificateLocations = "/root/Octopus/ca-bundle.crt"
            #endif
			guard SSL_CTX_load_verify_locations(ctx, certificateLocations, nil) == 1 else { print("SSL_CTX_load_verify_locations error"); return }
		}
	}

}
