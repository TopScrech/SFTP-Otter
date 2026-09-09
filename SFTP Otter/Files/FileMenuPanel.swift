#if os(macOS)
import AppKit

final class FileMenuPanel: NSPanel {
    var navigation = FileMenuNavigation()
    var perform: (FileMenuAction) -> Void = { _ in }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    
    override func resignKey() {
        super.resignKey()
        close()
    }
    
    override func cancelOperation(_ sender: Any?) { close() }
    
    override func sendEvent(_ event: NSEvent) {
        guard event.type == .keyDown else { super.sendEvent(event); return }
        switch event.keyCode {
        case 53: close()
        case 125: navigation.move(1)
        case 126: navigation.move(-1)
        case 36, 76:
            if let selected = navigation.selected { close(); perform(selected) }
        default:
            if event.modifierFlags.intersection([.command, .control, .option]).isEmpty,
               let text = event.characters, text.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }) {
                navigation.type(text)
            } else { super.sendEvent(event) }
        }
    }
}
#endif
