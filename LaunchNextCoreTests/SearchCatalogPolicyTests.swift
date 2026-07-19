import XCTest
@testable import LaunchNextCore

final class SearchCatalogPolicyTests: XCTestCase {
    private let visible = [
        SearchCatalogCandidate(id: "/Applications/Mail.app", displayName: "Mail", isHidden: false),
        SearchCatalogCandidate(id: "/Applications/Maps.app", displayName: "Maps", isHidden: false)
    ]

    private let hidden = [
        SearchCatalogCandidate(id: "/Applications/Chess.app", displayName: "Chess", isHidden: true),
        SearchCatalogCandidate(id: "/Applications/Mail.app", displayName: "Mail duplicate", isHidden: true)
    ]

    func testEmptyQueryNeverAddsHiddenCandidates() {
        let result = SearchCatalogPolicy.candidates(
            visible: visible,
            hidden: hidden,
            query: "   ",
            includesHidden: true
        )

        XCTAssertEqual(result, visible)
    }

    func testNonemptyQueryExcludesHiddenCandidatesByDefault() {
        let result = SearchCatalogPolicy.candidates(
            visible: visible,
            hidden: hidden,
            query: "ch",
            includesHidden: false
        )

        XCTAssertEqual(result, visible)
    }

    func testOptInAppendsHiddenCandidatesWithoutMutatingVisibleOrder() {
        let result = SearchCatalogPolicy.candidates(
            visible: visible,
            hidden: hidden,
            query: "ch",
            includesHidden: true
        )

        XCTAssertEqual(result.map(\.id), [
            "/Applications/Mail.app",
            "/Applications/Maps.app",
            "/Applications/Chess.app"
        ])
        XCTAssertEqual(result.last?.isHidden, true)
    }

    func testVisibleCandidateWinsWhenHiddenCatalogContainsSameIdentifier() {
        let result = SearchCatalogPolicy.candidates(
            visible: visible,
            hidden: hidden,
            query: "mail",
            includesHidden: true
        )

        let matching = result.filter { $0.id == "/Applications/Mail.app" }
        XCTAssertEqual(matching.count, 1)
        XCTAssertEqual(matching.first?.displayName, "Mail")
        XCTAssertEqual(matching.first?.isHidden, false)
    }
}
