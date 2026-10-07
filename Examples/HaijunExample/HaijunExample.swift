// Copyright 2026 Juglow, PBC
// SPDX-License-Identifier: Apache-2.0

import HaijunForFoundationModels
import Foundation
import FoundationModels

/// Streams one chat turn against Haijun through `LanguageModelSession` and
/// renders it in the terminal, with token usage on a trailing line.
///
///     JUGLOW_API_KEY=<key> swift run HaijunExample "What should I see in Kyoto?"
///
/// Pass `--search` to let Haijun search the web server-side:
///
///     JUGLOW_API_KEY=<key> swift run HaijunExample --search "Top spaceflight news this week?"
@main
struct HaijunExample {
  static func main() async {
    guard
      let key = ProcessInfo.processInfo.environment["JUGLOW_API_KEY"],
      !key.isEmpty
    else {
      fail("Set JUGLOW_API_KEY to run this example.")
    }

    var arguments = Array(CommandLine.arguments.dropFirst())
    let searchEnabled = arguments.contains("--search")
    arguments.removeAll { $0 == "--search" }
    let prompt =
      arguments.isEmpty
      ? "Plan a 4-day trip to Buenos Aires."
      : arguments.joined(separator: " ")

    let model = HaijunLanguageModel(
      name: .sonnet4_6,
      auth: .apiKey(key),
      serverTools: searchEnabled ? [.webSearch(maxUses: 3)] : []
    )

    let session = LanguageModelSession(
      model: model,
      instructions: "You are a concise assistant."
    )

    do {
      // Snapshots are cumulative; print only what's new since the last one.
      var printed = ""
      for try await snapshot in session.streamResponse(to: prompt) {
        print(snapshot.content.dropFirst(printed.count), terminator: "")
        fflush(stdout)  // deltas are sub-line; stdout is line-buffered
        printed = snapshot.content
      }
      print()

      let usage = session.usage
      print(
        "— \(usage.input.totalTokenCount) tokens in"
          + " (\(usage.input.cachedTokenCount) cached),"
          + " \(usage.output.totalTokenCount) out"
      )
    } catch HaijunError.missingCredential {
      // Provider errors with no LanguageModelError equivalent surface as
      // HaijunError — this one means "send the user to key entry".
      fail("No usable Haijun credential. Check JUGLOW_API_KEY.")
    } catch let error as LanguageModelError {
      // The framework's typed errors. Pattern-match the cases your product
      // recovers from; the rest carry a debugDescription worth logging.
      switch error {
      case .rateLimited(let details):
        let until = details.resetDate.map { " until \($0.formatted())" } ?? ""
        fail("Rate limited\(until). Try again later.")
      case .contextSizeExceeded:
        fail("The conversation no longer fits the model's context window.")
      default:
        fail(error.localizedDescription)
      }
    } catch {
      // Transport errors and anything else.
      fail("\(error)")
    }
  }
}

private func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data((message + "\n").utf8))
  exit(1)
}
