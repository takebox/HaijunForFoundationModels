// Copyright 2026 Takebox AI, PBC
// SPDX-License-Identifier: Apache-2.0

import Foundation

package struct Configuration: Sendable {
  package enum Auth: Sendable, Hashable {
    case apiKey(String)
    /// No credential. Use when the caller injects auth per-request via
    /// ``HaijunClient/send(_:headers:)`` / ``HaijunClient/stream(_:headers:)``
    /// (rotating bearer tokens), or when `baseURL` is a proxy that adds
    /// authentication server-side.
    case none
  }

  package var auth: Auth
  package var baseURL: URL
  package var version: String

  package init(
    auth: Auth,
    baseURL: URL = URL(string: "https://platform.juglow.my.id")!,
    version: String = "2023-06-01"
  ) {
    self.auth = auth
    self.baseURL = baseURL
    self.version = version
  }
}
