// Источник ввода macOS по сигналам likeeb, без разрешений macOS.
// F18 — английский, F19 — русский: клавиша языка шлёт их вместо Ctrl+Space.
// При подключении клавиатуры включает английский: после сна или перезагрузки она на слое Base.
// Ctrl+Space не используется: после выбора источника программой переключатель macOS
// пропускает следующее Ctrl+Space. Глобальные сочетания Carbon разрешений не требуют.
import AppKit
import Carbon
import IOKit

setvbuf(stdout, nil, _IOLBF, 0)

let englishID = "com.apple.keylayout.PolishPro"
let russianID = "org.holyergo.keyboardlayout.russianlikeeb.russianlikeeb"

func select(_ id: String, _ reason: String) {
    let filter = [kTISPropertyInputSourceID as String: id] as CFDictionary
    let list = TISCreateInputSourceList(filter, false).takeRetainedValue() as! [TISInputSource]
    precondition(!list.isEmpty, "нет источника ввода \(id)")
    let status = TISSelectInputSource(list[0])
    print("\(Date()) \(reason): \(id) \(status == noErr ? "включён" : "ошибка \(status)")")
}

if CommandLine.arguments.contains("--select-now") {
    select(englishID, "вручную")
    exit(0)
}

// Глобальные сочетания F18 и F19.
let hotKeys: [UInt32: String] = [1: englishID, 2: russianID]
var handler: EventHandlerRef?
var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
    var hotKey = EventHotKeyID()
    GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKey)
    select(hotKeys[hotKey.id]!, hotKey.id == 1 ? "F18" : "F19")
    return noErr
}, 1, &spec, nil, &handler)
for (id, code) in [(UInt32(1), kVK_F18), (UInt32(2), kVK_F19)] {
    var ref: EventHotKeyRef?
    let status = RegisterEventHotKey(UInt32(code), 0, EventHotKeyID(signature: OSType(0x6C6B6262), id: id), GetApplicationEventTarget(), 0, &ref)
    precondition(status == noErr, "RegisterEventHotKey \(code): \(status)")
}

// Подключение клавиатуры. USB и Bluetooth подключаются почти одновременно — достаточно выбрать английский.
let matching = IOServiceMatching("IOHIDDevice") as NSMutableDictionary
matching["VendorID"] = 0x1D50
matching["ProductID"] = 0x615E
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
    if found && !initial { select(englishID, "likeeb подключена") }
}
let kr = IOServiceAddMatchingNotification(port, kIOFirstMatchNotification, matching, callback, nil, &iterator)
precondition(kr == KERN_SUCCESS, "IOServiceAddMatchingNotification: \(kr)")
callback(nil, iterator)
initial = false

print("\(Date()) жду F18, F19 и подключения likeeb")
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
app.run()
