// Copyright 2026 Takebox AI, PBC
// SPDX-License-Identifier: Apache-2.0

import HaijunAPI
import Foundation
import FoundationModels

/// Substitute models for when the requested model declines a request.
///
/// Some models decline requests in certain policy areas, such as
/// cybersecurity or biology. With fallbacks, the API retries a declined
/// request on a substitute model, within the same request:
///
/// ```swift
/// HaijunLanguageModel(name: .opus5, auth: auth, fallbacks: [.opus4_8])
/// ```
///
/// A model can decline after it has started to answer. The fallback model
/// then continues from the declining model's text, so the response reads as
/// one answer. The transcript marks the handover (see ``HaijunModelHandover``).
///
/// After a fallback, the API serves the conversation's next requests straight
/// from the fallback model, for about an hour, as long as those requests
/// still name it. Those responses have no handover.
/// ``FoundationModels/Transcript/Response/haijunModelID`` names the model
/// that served each response.
///
/// Each fallback gets the thinking and effort it accepts, the same way the
/// requested model does. A fixed effort becomes the closest level the fallback
/// accepts. The rest of the request, including the prompt, the tools, and any
/// sampling settings, reaches the fallback unchanged.
public enum HaijunFallbacks: Sendable, Hashable, ExpressibleByArrayLiteral {
  /// Up to three substitute models, tried in order. Each must be one the
  /// requested model allows as a fallback, and the API rejects any other.
  /// An empty list means no fallbacks.
  case models([HaijunModel])
  /// The requested model's default fallback configuration. The API chooses
  /// the substitute that's recommended for the policy area of the refusal, and
  /// for an area with no recommended fallback, the refusal stands. The API
  /// rejects `fallbacks` in either form for a model that doesn't support them.
  /// The bridge can't check the capabilities of models it doesn't know, so
  /// their request fields follow the requested model's capabilities.
  case serverDefault

  public init(arrayLiteral models: HaijunModel...) {
    self = .models(models)
  }

  /// The models this package knows will be tried: empty for
  /// ``serverDefault``, whose models the API chooses.
  var knownModels: [HaijunModel] {
    if case .models(let models) = self { models } else { [] }
  }
}
