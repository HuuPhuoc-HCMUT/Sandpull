import Foundation

/// Render-ready marker passed directly to DragOverlayView.
/// Contains no business logic — only display data.
struct TimelineMarker {
    let title: String
    let time: String        // formatted start time, e.g. "4:00 PM"
    let position: CGFloat   // 0.0 = drag origin (now), 1.0 = drag end (selected end time)
    let isWarning: Bool     // true when the timer end time falls inside this event
}
