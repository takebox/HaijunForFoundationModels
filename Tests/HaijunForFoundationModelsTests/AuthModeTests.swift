// Copyright 2026 Juglow, PBC
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Testing

@testable import HaijunForFoundationModels

@Suite struct AuthModeTests {
  @Test func `proxied modes differ by their headers`() {
    #expect(AuthMode.proxied(headers: ["a": "1"]) == AuthMode.proxied(headers: ["a": "1"]))
    #expect(AuthMode.proxied(headers: ["a": "1"]) != AuthMode.proxied(headers: ["a": "2"]))
    #expect(AuthMode.proxied(headers: [:]) != AuthMode.apiKey("k"))
  }

  @Test func `appAttest identity is the client id`() {
    #expect(AuthMode.appAttest(clientID: "a") == AuthMode.appAttest(clientID: "a"))
    #expect(AuthMode.appAttest(clientID: "a") != AuthMode.appAttest(clientID: "b"))
  }

  /// Proxy headers must participate in the executor cache key, so two models
  /// that differ only by their proxy headers get distinct cached executors.
  @Test func `proxy headers drive the executor configuration identity`() {
    func config(_ auth: AuthMode) -> HaijunExecutor.Configuration {
      .init(
        model: .sonnet4_6,
        baseURL: HaijunLanguageModel.defaultBaseURL,
        authMode: auth,
        timeout: 60 )
    }
    #expect(config(.proxied(headers: ["a": "1"])) == config(.proxied(headers: ["a": "1"])))
    #expect(config(.proxied(headers: ["a": "1"])) != config(.proxied(headers: ["a": "2"])))
  }
}
