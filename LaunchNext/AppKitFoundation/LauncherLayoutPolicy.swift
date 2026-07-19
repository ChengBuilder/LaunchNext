import CoreGraphics
import Foundation

nonisolated enum LauncherLayoutMode: Equatable, Sendable {
    case compact
    case fullscreen
}

nonisolated struct LauncherLayoutRequest: Equatable, Sendable {
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

nonisolated struct LauncherEdgeInsets: Equatable, Sendable {
    let top: CGFloat
    let left: CGFloat
    let bottom: CGFloat
    let right: CGFloat
}

nonisolated struct LauncherLayoutMetrics: Equatable, Sendable {
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

nonisolated enum LauncherLayoutPolicy {
    private static let fallbackSize = CGSize(width: 320, height: 240)
    private static let maximumDimension: CGFloat = 1_000_000
    private static let minimumIconSize: CGFloat = 16
    private static let maximumTrackCount = 64
    private static let cellHorizontalClearance: CGFloat = 16
    private static let cellVerticalClearance: CGFloat = 10
    private static let iconLabelSpacing: CGFloat = 6

    static func resolve(_ request: LauncherLayoutRequest) -> LauncherLayoutMetrics {
        let size = CGSize(
            width: positiveFinite(request.availableSize.width, fallback: fallbackSize.width),
            height: positiveFinite(request.availableSize.height, fallback: fallbackSize.height)
        )
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

        let contentBottomY = max(insets.top, size.height - insets.bottom)
        let gridOriginY = min(contentBottomY, toolbarFrame.maxY + toolbarToGridSpacing)
        let availableIndicatorHeight = min(
            pageIndicatorHeight,
            max(0, contentBottomY - gridOriginY)
        )
        let pageIndicatorY = max(gridOriginY, contentBottomY - availableIndicatorHeight)
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
            height: availableIndicatorHeight
        )

        let minimumCellWidth = minimumIconSize + cellHorizontalClearance
        let minimumCellHeight = minimumIconSize + labelHeight
            + (labelHeight == 0 ? 0 : iconLabelSpacing)
            + cellVerticalClearance
        let columns = resolvedCount(
            preferred: request.preferredColumns,
            available: gridFrame.width,
            spacing: columnSpacing,
            minimumCell: minimumCellWidth
        )
        let rows = resolvedCount(
            preferred: request.preferredRows,
            available: gridFrame.height,
            spacing: rowSpacing,
            minimumCell: minimumCellHeight
        )
        let horizontalGaps = min(gridFrame.width, columnSpacing * CGFloat(max(0, columns - 1)))
        let verticalGaps = min(gridFrame.height, rowSpacing * CGFloat(max(0, rows - 1)))
        let cellSize = CGSize(
            width: max(0, (gridFrame.width - horizontalGaps) / CGFloat(columns)),
            height: max(0, (gridFrame.height - verticalGaps) / CGFloat(rows))
        )
        let labelBlockHeight = labelHeight == 0 ? 0 : labelHeight + iconLabelSpacing
        let maximumIconSize = max(0, min(
            cellSize.width - cellHorizontalClearance,
            cellSize.height - labelBlockHeight - cellVerticalClearance
        ))
        let iconSize = min(preferredIconSize, maximumIconSize)

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
        let desired: LauncherEdgeInsets
        switch mode {
        case .compact:
            desired = LauncherEdgeInsets(top: 20, left: 24, bottom: 20, right: 24)
        case .fullscreen:
            let horizontal = max(36, size.width * 0.04)
            desired = LauncherEdgeInsets(
                top: max(24, size.height * 0.035),
                left: horizontal,
                bottom: max(32, size.height * 0.06),
                right: horizontal
            )
        }
        return LauncherEdgeInsets(
            top: min(desired.top, size.height),
            left: min(desired.left, size.width),
            bottom: min(desired.bottom, max(0, size.height - min(desired.top, size.height))),
            right: min(desired.right, max(0, size.width - min(desired.left, size.width)))
        )
    }

    private static func resolvedCount(
        preferred: Int,
        available: CGFloat,
        spacing: CGFloat,
        minimumCell: CGFloat
    ) -> Int {
        guard available >= minimumCell else { return 1 }
        let maximum = min(
            maximumTrackCount,
            Int(floor((available + spacing) / (minimumCell + spacing)))
        )
        return min(max(1, preferred), max(1, maximum))
    }

    private static func positiveFinite(_ value: CGFloat, fallback: CGFloat) -> CGFloat {
        guard value.isFinite, value > 0 else { return fallback }
        return min(value, maximumDimension)
    }

    private static func nonnegativeFinite(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return 0 }
        return max(0, value)
    }
}
