import Foundation
import OSLog

nonisolated enum LaunchPerformance {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "io.roversx.launchnext"
    private static let log = OSLog(subsystem: subsystem, category: .pointsOfInterest)

    enum Name {
        static let appLaunch: StaticString = "app_entry_to_did_finish_launching"
        static let firstInteractiveFrame: StaticString = "launch_to_first_interactive_frame"
        static let catalogScan: StaticString = "catalog_scan"
        static let catalogCacheSchedule: StaticString = "catalog_cache_schedule"
        static let windowShow: StaticString = "window_show"
        static let windowHide: StaticString = "window_hide"
        static let folderOpen: StaticString = "folder_open"
        static let folderClose: StaticString = "folder_close"
        static let pageAnimation: StaticString = "page_animation"
    }

    @discardableResult
    static func begin(_ name: StaticString) -> OSSignpostID {
        let identifier = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: name, signpostID: identifier)
        return identifier
    }

    static func end(_ name: StaticString, identifier: OSSignpostID) {
        os_signpost(.end, log: log, name: name, signpostID: identifier)
    }

    static func event(_ name: StaticString) {
        os_signpost(.event, log: log, name: name)
    }
}
