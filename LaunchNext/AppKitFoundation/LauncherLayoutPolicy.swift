import CoreGraphics
import Foundation

enum LauncherLayoutMode: Equatable, Sendable {
    case compact
    case fullscreen
}

struct LauncherLayoutRequest: Equatable, Sendable {
    let availableSize: CGSize
    let mode: LauncherLayoutMode
    let preferredColumns: Int
    let preferredRows: Int
    let preferredIconSize: CGFloat
    let columnSpacing: CGFloat
    let rowSpacing: CGFloat
    let showsLabels: Bool
    let labelHeight: CGFloat
}

struct LauncherEdgeInsets: Equatable, Sendable {
    let top: CGFloat
    let left: CGFloat
    let bottom: CGFloat
    let right: CGFloat
}

struct LauncherLayoutMetrics: Equatable, Sendable {
    let availableSize: CGSize
    let columns: Int
    let rows: Int
    let iconSize: CGFloat
    let columnSpacing: CGFloat
    let rowSpacing: CGFloat
    let contentInsets: LauncherEdgeInsets
    let toolbarFrame: CGRect
    let gridFrame: CGRect
    let pageIndicatorFrame: CGRect
    let cellSize: CGSize

    var itemsPerPage: Int { columns * rows }
}

enum LauncherLayoutPolicy {
    private static let fallbackSize = CGSize(width: 320, height: 240)
    private static let minimumIconSize: CGFloat = 16
    private static let cellHorizontalClearance: CGFloat = 16
    private static let cellVerticalClearance: CGFloat = 10
    private static let iconLabelSpacing: CGFloat = 6

    static func resolve(_ request: LauncherLayoutRequest) -> LauncherLayoutMetrics {
        let size = CGSize(
            width: positiveFinite(request.availableSize.width, fallback: fallbackSize.width),
            height: positiveFinite(request.availableSize.height, fallback: fallbackSize.height)
        )
        let columns = max(1, request.preferredColumns)
        let rows = max(1, request.preferredRows)
        let columnSpacing = nonnegativeFinite(request.columnSpacing)
        let rowSpacing = nonnegativeFinite(request.rowSpacing)
        let preferredIconSize = positiveFinite(request.preferredIconSize, fallback: 72)
        let labelHeight = request.showsLabels ? nonnegativeFinite(request.labelHeight) : 0

        let insets = contentInsets(for: request.mode, size: size)
        let toolbarHeight: CGFloat = request.mode == .fullscreen ? 52 : 48
        let toolbarToGridSpacing: CGFloat = 12
        let pageIndicatorHeight: CGFloat = 20
        let gridToPageIndicatorSpacing: CGFloat = 12

        let contentWidth = max(0, size.width - insets.left - insets.right)
        let toolbarFrame = CGRect(
            x: insets.left,
            y: insets.top,
            width: contentWidth,
            height: min(toolbarHeight, max(0, size.height - insets.top - insets.bottom))
        )

        let gridOriginY = toolbarFrame.maxY + toolbarToGridSpacing
        let pageIndicatorY = max(
            gridOriginY,
            size.height - insets.bottom - pageIndicatorHeight
        )
        let gridHeight = max(0, pageIndicatorY - gridToPageIndicatorSpacing - gridOriginY)
        let gridFrame = CGRect(
            x: insets.left,
            y: gridOriginY,
            width: contentWidth,
            height: gridHeight
        )
        let pageIndicatorFrame = CGRect(
            x: insets.left,
            y: pageIndicatorY,
            width: contentWidth,
            height: min(pageIndicatorHeight, max(0, size.height - pageIndicatorY - insets.bottom))
        )

        let horizontalGaps = columnSpacing * CGFloat(max(0, columns - 1))
        let verticalGaps = rowSpacing * CGFloat(max(0, rows - 1))
        let cellSize = CGSize(
            width: max(0, (gridFrame.width - horizontalGaps) / CGFloat(columns)),
            height: max(0, (gridFrame.height - verticalGaps) / CGFloat(rows))
        )
        let labelBlockHeight = labelHeight == 0 ? 0 : labelHeight + iconLabelSpacing
        let maximumIconSize = min(
            max(minimumIconSize, cellSize.width - cellHorizontalClearance),
            max(minimumIconSize, cellSize.height - labelBlockHeight - cellVerticalClearance)
        )
        let iconSize = max(minimumIconSize, min(preferredIconSize, maximumIconSize))

        return LauncherLayoutMetrics(
            availableSize: size,
            columns: columns,
            rows: rows,
            iconSize: iconSize,
            columnSpacing: columnSpacing,
            rowSpacing: rowSpacing,
            contentInsets: insets,
            toolbarFrame: toolbarFrame,
            gridFrame: gridFrame,
            pageIndicatorFrame: pageIndicatorFrame,
            cellSize: cellSize
        )
    }

    private static func contentInsets(
        for mode: LauncherLayoutMode,
        size: CGSize
    ) -> LauncherEdgeInsets {
        switch mode {
        case .compact:
            return LauncherEdgeInsets(top: 20, left: 24, bottom: 20, right: 24)
        case .fullscreen:
            let horizontal = max(36, size.width * 0.04)
            return LauncherEdgeInsets(
                top: max(24, size.height * 0.035),
                left: horizontal,
                bottom: max(32, size.height * 0.06),
                right: horizontal
            )
        }
    }

    private static func positiveFinite(_ value: CGFloat, fallback: CGFloat) -> CGFloat {
        guard value.isFinite, value > 0 else { return fallback }
        return value
    }

    private static func nonnegativeFinite(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return 0 }
        return max(0, value)
    }
}
