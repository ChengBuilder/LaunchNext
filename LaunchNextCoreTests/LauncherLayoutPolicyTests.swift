import CoreGraphics
import XCTest
@testable import LaunchNextCore

final class LauncherLayoutPolicyTests: XCTestCase {
    func testPreferredGridIsPreservedWhenItFits() {
        let request = LauncherLayoutRequest(
            availableSize: CGSize(width: 1512, height: 949),
            mode: .fullscreen,
            preferredColumns: 8,
            preferredRows: 5,
            preferredIconSize: 88,
            columnSpacing: 24,
            rowSpacing: 28,
            showsLabels: true,
            labelHeight: 22
        )

        let metrics = LauncherLayoutPolicy.resolve(request)

        XCTAssertEqual(metrics.columns, 8)
        XCTAssertEqual(metrics.rows, 5)
        XCTAssertEqual(metrics.iconSize, 88, accuracy: 0.001)
        XCTAssertEqual(metrics.itemsPerPage, 40)
        assertContained(metrics.gridFrame, in: request.availableSize)
    }

    func testCompactLayoutShrinksIconsBeforeDroppingGridCapacity() {
        let request = LauncherLayoutRequest(
            availableSize: CGSize(width: 800, height: 600),
            mode: .compact,
            preferredColumns: 7,
            preferredRows: 5,
            preferredIconSize: 96,
            columnSpacing: 24,
            rowSpacing: 24,
            showsLabels: true,
            labelHeight: 20
        )

        let metrics = LauncherLayoutPolicy.resolve(request)

        XCTAssertEqual(metrics.columns, 7)
        XCTAssertEqual(metrics.rows, 5)
        XCTAssertLessThan(metrics.iconSize, request.preferredIconSize)
        XCTAssertGreaterThanOrEqual(metrics.iconSize, 32)
        assertContained(metrics.gridFrame, in: request.availableSize)
    }

    func testInvalidInputsResolveToFiniteUsableMetrics() {
        let request = LauncherLayoutRequest(
            availableSize: CGSize(width: -20, height: CGFloat.infinity),
            mode: .compact,
            preferredColumns: 0,
            preferredRows: -4,
            preferredIconSize: CGFloat.nan,
            columnSpacing: -8,
            rowSpacing: CGFloat.infinity,
            showsLabels: false,
            labelHeight: -10
        )

        let metrics = LauncherLayoutPolicy.resolve(request)

        XCTAssertEqual(metrics.columns, 1)
        XCTAssertEqual(metrics.rows, 1)
        XCTAssertTrue(metrics.iconSize.isFinite)
        XCTAssertGreaterThanOrEqual(metrics.iconSize, 16)
        XCTAssertTrue(metrics.gridFrame.origin.x.isFinite)
        XCTAssertTrue(metrics.gridFrame.origin.y.isFinite)
        XCTAssertTrue(metrics.gridFrame.width.isFinite)
        XCTAssertTrue(metrics.gridFrame.height.isFinite)
    }

    func testTinyAvailableSizeKeepsFramesContained() {
        let request = LauncherLayoutRequest(
            availableSize: CGSize(width: 1, height: 1),
            mode: .compact,
            preferredColumns: 7,
            preferredRows: 5,
            preferredIconSize: 72,
            columnSpacing: 24,
            rowSpacing: 24,
            showsLabels: true,
            labelHeight: 20
        )

        let metrics = LauncherLayoutPolicy.resolve(request)

        XCTAssertEqual(metrics.columns, 1)
        XCTAssertEqual(metrics.rows, 1)
        XCTAssertEqual(metrics.iconSize, 0)
        assertContained(metrics.toolbarFrame, in: request.availableSize)
        assertContained(metrics.gridFrame, in: request.availableSize)
        assertContained(metrics.pageIndicatorFrame, in: request.availableSize)
    }

    func testExtremelyLargeInputsStayFiniteAndBounded() {
        let request = LauncherLayoutRequest(
            availableSize: CGSize(width: CGFloat.greatestFiniteMagnitude,
                                  height: CGFloat.greatestFiniteMagnitude),
            mode: .fullscreen,
            preferredColumns: .max,
            preferredRows: .max,
            preferredIconSize: CGFloat.greatestFiniteMagnitude,
            columnSpacing: CGFloat.greatestFiniteMagnitude,
            rowSpacing: CGFloat.greatestFiniteMagnitude,
            showsLabels: true,
            labelHeight: CGFloat.greatestFiniteMagnitude
        )

        let metrics = LauncherLayoutPolicy.resolve(request)

        XCTAssertTrue(metrics.gridFrame.origin.x.isFinite)
        XCTAssertTrue(metrics.gridFrame.origin.y.isFinite)
        XCTAssertTrue(metrics.gridFrame.width.isFinite)
        XCTAssertTrue(metrics.gridFrame.height.isFinite)
        XCTAssertTrue(metrics.iconSize.isFinite)
        XCTAssertLessThanOrEqual(metrics.columns, 64)
        XCTAssertLessThanOrEqual(metrics.rows, 64)
        XCTAssertLessThanOrEqual(metrics.itemsPerPage, 4096)
    }

    func testOversubscribedGridReducesCapacityBeforeViolatingMinimumIconSize() {
        let request = LauncherLayoutRequest(
            availableSize: CGSize(width: 800, height: 600),
            mode: .compact,
            preferredColumns: 100,
            preferredRows: 100,
            preferredIconSize: 96,
            columnSpacing: 24,
            rowSpacing: 24,
            showsLabels: true,
            labelHeight: 20
        )

        let metrics = LauncherLayoutPolicy.resolve(request)

        XCTAssertLessThan(metrics.columns, request.preferredColumns)
        XCTAssertLessThan(metrics.rows, request.preferredRows)
        XCTAssertGreaterThanOrEqual(metrics.iconSize, 16)
        assertContained(metrics.gridFrame, in: request.availableSize)
    }

    func testResolvingTheSameRequestIsStable() {
        let request = LauncherLayoutRequest(
            availableSize: CGSize(width: 1200, height: 800),
            mode: .fullscreen,
            preferredColumns: 9,
            preferredRows: 5,
            preferredIconSize: 80,
            columnSpacing: 20,
            rowSpacing: 24,
            showsLabels: true,
            labelHeight: 20
        )

        XCTAssertEqual(
            LauncherLayoutPolicy.resolve(request),
            LauncherLayoutPolicy.resolve(request)
        )
    }

    private func assertContained(
        _ frame: CGRect,
        in size: CGSize,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertGreaterThanOrEqual(frame.minX, 0, file: file, line: line)
        XCTAssertGreaterThanOrEqual(frame.minY, 0, file: file, line: line)
        XCTAssertLessThanOrEqual(frame.maxX, size.width, file: file, line: line)
        XCTAssertLessThanOrEqual(frame.maxY, size.height, file: file, line: line)
    }
}
