// Включает английский источник ввода macOS, когда likeeb подключается к Маку.
// Клавиатура подключается после сна или перезагрузки и всегда начинает со слоя Base (английский).
import Carbon
import Foundation
import IOKit

setvbuf(stdout, nil, _IOLBF, 0)

let englishID = "com.apple.keylayout.PolishPro"
let matching = IOServiceMatching("IOHIDDevice") as NSMutableDictionary
matching["VendorID"] = 0x1D50
matching["ProductID"] = 0x615E

func selectEnglish() {
    let filter = [kTISPropertyInputSourceID as String: englishID] as CFDictionary
    let list = TISCreateInputSourceList(filter, false).takeRetainedValue() as! [TISInputSource]
    precondition(!list.isEmpty, "нет источника ввода \(englishID)")
    let status = TISSelectInputSource(list[0])
    print("\(Date()) likeeb подключена, \(englishID): \(status == noErr ? "включён" : "ошибка \(status)")")
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
