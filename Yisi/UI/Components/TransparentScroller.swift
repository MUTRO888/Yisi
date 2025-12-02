import Cocoa

/// A custom NSScroller that does not draw the background track (knob slot).
/// This creates a "floating" scrollbar effect similar to iOS or modern macOS overlay scrollers,
/// but explicitly forces the track to be invisible even if the system would otherwise draw it.
class TransparentScroller: NSScroller {
    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        // Do nothing: prevents drawing the background track
    }
}
