import Foundation

nonisolated struct SearchCatalogCandidate: Equatable, Sendable {
    let id: String
    let displayName: String
    let isHidden: Bool
}

nonisolated enum SearchCatalogPolicy {
    static func candidates(
        visible: [SearchCatalogCandidate],
        hidden: [SearchCatalogCandidate],
        query: String,
        includesHidden: Bool
    ) -> [SearchCatalogCandidate] {
        guard includesHidden,
              !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return visible
        }

        var seenIdentifiers = Set(visible.map(\.id))
        var result = visible
        result.reserveCapacity(visible.count + hidden.count)

        for candidate in hidden where seenIdentifiers.insert(candidate.id).inserted {
            result.append(candidate)
        }

        return result
    }
}
