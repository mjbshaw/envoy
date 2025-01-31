@_spi(YAMLValidation)
import Envoy
import EnvoyEngine
import Foundation
import TestExtensions
import XCTest

final class SetEventTrackerTestNoTracker: XCTestCase {
  override static func setUp() {
    super.setUp()
    register_test_extensions()
  }

  // Skipping because this test currently attempts to connect to an invalid remote (example.com)
  func skipped_testSetEventTracker() throws {
    let expectation = self.expectation(description: "Response headers received")

    let engine = YAMLValidatingEngineBuilder()
      .addLogLevel(.trace)
      .addNativeFilter(
        name: "envoy.filters.http.test_event_tracker",
        // swiftlint:disable:next line_length
        typedConfig: "{\"@type\":\"type.googleapis.com/envoymobile.extensions.filters.http.test_event_tracker.TestEventTracker\",\"attributes\":{\"foo\":\"bar\"}}")
      .build()

    let client = engine.streamClient()

    let requestHeaders = RequestHeadersBuilder(method: .get, scheme: "https",
                                               authority: "example.com", path: "/test")
      .build()

    client
      .newStreamPrototype()
      .setOnResponseHeaders { _, _, _ in
        expectation.fulfill()
      }
      .start()
      .sendHeaders(requestHeaders, endStream: true)

    XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 10), .completed)

    engine.terminate()
  }
}
