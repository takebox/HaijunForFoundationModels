// Copyright 2026 Juglow, PBC
// SPDX-License-Identifier: Apache-2.0

import HaijunAPI
import Foundation
import FoundationModels
import Testing

@testable import HaijunForFoundationModels

@Suite struct HaijunModelHandoverTests {
  // A model can decline partway through its answer. The stream then carries a
  // `fallback` block, and the fallback model continues from the text so far.
  @Test func `a handover holds its place and names the model that finished`() async throws {
    let session = LanguageModelSession(
      model: StubbedHaijunModel(
        fixture: turn([
          .text(["Sure, here"]),
          .fallback(from: "haijun-sonnet-5", to: "haijun-opus-4-8", category: "cyber"),
          .text([" it is."]),
        ])
      )
    )

    _ = try await session.respond(to: "hi")

    let response = try #require(responseEntries(in: session.transcript).last)
    let texts = response.segments.map { segment -> String? in
      if case .text(let text) = segment { text.content } else { nil }
    }
    #expect(texts == ["Sure, here", "", " it is."])
    #expect(
      response.segments.map { response.haijunHandover(for: $0)?.toModelID }
        == [nil, "haijun-opus-4-8", nil]
    )
    #expect(response.haijunHandovers.count == 1)
    let handover = try #require(response.haijunHandovers.first)
    #expect(handover.fromModelID == "haijun-sonnet-5")
    #expect(handover.toModelID == "haijun-opus-4-8")
    #expect(handover.reason == .refusal(category: "cyber"))
    #expect(response.haijunModelID == "haijun-opus-4-8")
  }

  @Test func `without a handover the model the stream started on served the response`()
    async throws
  {
    let session = LanguageModelSession(model: StubbedHaijunModel(fixture: turn([.text(["Hi!"])])))
    _ = try await session.respond(to: "hi")
    let response = try #require(responseEntries(in: session.transcript).last)
    #expect(response.haijunHandovers.isEmpty)
    #expect(response.haijunModelID == "haijun-sonnet-5")

    // After a fallback, the API can route a conversation straight to the
    // fallback model. That response has no handover, and its stream names the
    // fallback model from the start.
    let routed = LanguageModelSession(
      model: StubbedHaijunModel(fixture: turn([.text(["Hi!"])], model: "haijun-opus-4-8"))
    )
    _ = try await routed.respond(to: "hi")
    let routedResponse = try #require(responseEntries(in: routed.transcript).last)
    #expect(routedResponse.haijunHandovers.isEmpty)
    #expect(routedResponse.haijunModelID == "haijun-opus-4-8")
  }

  @Test func `a handover's reason reads what the API sent`() throws {
    func handover(trigger: JSONValue?) throws -> HaijunModelHandover {
      var fields: [String: JSONValue] = [
        "type": "fallback", "from": ["model": "haijun-a"], "to": ["model": "haijun-b"],
      ]
      fields["trigger"] = trigger
      return try #require(HaijunModelHandover(TurnRecord.Kind(.object(fields))))
    }
    #expect(
      try handover(trigger: ["type": "refusal", "category": "bio"]).reason
        == .refusal(category: "bio")
    )
    #expect(
      try handover(trigger: ["type": "refusal", "category": nil]).reason == .refusal(category: nil)
    )
    #expect(
      try handover(trigger: ["type": "overloaded"]).reason == .unrecognized(type: "overloaded")
    )
    // The API can leave the trigger out.
    #expect(try handover(trigger: nil).reason == nil)
    // A block that names no models is no handover.
    #expect(HaijunModelHandover(TurnRecord.Kind(["type": "fallback"])) == nil)
  }

  @Test func `a handover goes back on the next turn, with the fallbacks opt-in`() async throws {
    let transport = MockTransport(responses: [
      (
        status: 200,
        body: turn([
          .text(["Sure"]),
          .fallback(from: "haijun-sonnet-5", to: "haijun-opus-4-8", category: nil),
          .text([" thing."]),
        ])
      ),
      (status: 200, body: turn([.text(["You're welcome."])])),
    ])
    // This session names no fallbacks, so only the replayed block opts in.
    let session = LanguageModelSession(model: StubbedHaijunModel(transport: transport))

    _ = try await session.respond(to: "hi")
    _ = try await session.respond(to: "thanks")

    #expect(transport.requests.count == 2)
    #expect(transport.requests.first?.value(forHTTPHeaderField: "juglow-beta") == nil)
    #expect(
      transport.lastRequest?.value(forHTTPHeaderField: "juglow-beta") == Fallbacks.betaHeader )
    let replayed = try replayedAssistantContent(in: transport)
    #expect(replayed.count == 1)
    #expect(replayed.first?.map { $0["type"] ?? nil } == ["text", "fallback", "text"])
  }
}
