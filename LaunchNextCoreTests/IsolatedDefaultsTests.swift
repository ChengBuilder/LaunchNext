import Foundation
import XCTest

final class IsolatedDefaultsTests: XCTestCase {
    func testFixtureSuiteDoesNotWriteToStandardDefaults() {
        let sentinelKey = "LaunchNextCoreTests.sentinel.\(UUID().uuidString)"
        let suiteName = "LaunchNextCoreTests.fixture.\(UUID().uuidString)"
        let standardDefaults = UserDefaults.standard
        XCTAssertNil(standardDefaults.object(forKey: sentinelKey))

        guard let fixtureDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Unable to create isolated fixture defaults")
            return
        }
        defer {
            fixtureDefaults.removePersistentDomain(forName: suiteName)
        }

        fixtureDefaults.set("fixture", forKey: sentinelKey)

        XCTAssertEqual(fixtureDefaults.string(forKey: sentinelKey), "fixture")
        XCTAssertNil(standardDefaults.object(forKey: sentinelKey))
    }
}
