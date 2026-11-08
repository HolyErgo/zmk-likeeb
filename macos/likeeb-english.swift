// Включает английский источник ввода macOS, когда likeeb подключается к Маку.
// Клавиатура подключается после сна или перезагрузки и всегда начинает со слоя Base (английский).
// Язык переключается нажатием Ctrl+Space, а не TISSelectInputSource: после программного выбора
// переключатель macOS пропускает следующее Ctrl+Space. Нужно разрешение «Универсальный доступ».
import Carbon
import CoreGraphics
import Foundation
import IOKit

setvbuf(stdout, nil, _IOLBF, 0)

let englishID = "com.apple.keylayout.PolishPro"
let matching = IOServiceMatching("IOHIDDevice") as NSMutableDictionary
matching["VendorID"] = 0x1D50
matching["ProductID"] = 0x615E

func currentID() -> String {
    let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
    return Unmanaged<CFString>.fromOpaque(TISGetInputSourceProperty(source, kTISPropertyInputSourceID)).takeUnretainedValue() as String
}

func key(_ code: CGKeyCode, down: Bool) {
    let event = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: down)!
    event.flags = .maskControl
    event.post(tap: .cghidEventTap)
}

// Space держится 150 мс, как в прошивке.
func pressControlSpace() {
    key(CGKeyCode(kVK_Control), down: true)
    usleep(30_000)
    key(CGKeyCode(kVK_Space), down: true)
    usleep(150_000)
    key(CGKeyCode(kVK_Space), down: false)
    usleep(30_000)
    let up = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Control), keyDown: false)!
    up.post(tap: .cghidEventTap)
}

// USB и Bluetooth подключаются почти одновременно: второе подключение в течение 5 с пропускаем.
var lastHandled = Date.distantPast

func selectEnglish() {
    if Date().timeIntervalSince(lastHandled) < 5 { return }
    lastHandled = Date()
    let before = currentID()
    if before == englishID {
        print("\(Date()) likeeb подключена, уже \(englishID)")
        return
    }
    pressControlSpace()
    // Смена языка после пробуждения клавиатуры может занять больше секунды.
    for _ in 0..<60 where currentID() == before { usleep(50_000) }
    print("\(Date()) likeeb подключена, Ctrl+Space: \(before) → \(currentID())")
}

if !CGPreflightPostEventAccess() {
    print("\(Date()) нет разрешения «Универсальный доступ», запрашиваю")
    CGRequestPostEventAccess()
}

if CommandLine.arguments.contains("--select-now") {
    selectEnglish()
    exit(0)
}

let port = IONotificationPortCreate(kIOMainPortDefault)
CFRunLoopAddSource(CFRunLoopGetMain(), IONotificationPortGetRunLoopSource(port).takeUnretainedValue(), .defaultMode)

var iterator: io_iterator_t = 0
// Первый проход по уже подключённым устройствам пропускаем: язык меняется только при новом подключении.
var initial = true
let callback: IOServiceMatchingCallback = { _, iterator in
    var found = false
    while case let service = IOIteratorNext(iterator), service != 0 {
        found = true
        IOObjectRelease(service)
    }
    if found && !initial { selectEnglish() }
}
let kr = IOServiceAddMatchingNotification(port, kIOFirstMatchNotification, matching, callback, nil, &iterator)
precondition(kr == KERN_SUCCESS, "IOServiceAddMatchingNotification: \(kr)")
callback(nil, iterator)
initial = false
print("\(Date()) жду подключения likeeb")
CFRunLoopRun()
