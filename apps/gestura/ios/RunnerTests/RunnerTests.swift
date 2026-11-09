import Flutter
import UIKit
import XCTest

class RunnerTests: XCTestCase {

  func testBundleIdentifierBelongsToGestura() {
    let identifier = Bundle.main.bundleIdentifier ?? ""
    XCTAssertTrue(identifier.hasPrefix("app.gestura.com"))
  }

}
