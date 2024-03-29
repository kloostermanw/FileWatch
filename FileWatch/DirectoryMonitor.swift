//
//  DirectoryMonitor.swift
//  FileWatch
//
//  Created by Wiebe Kloosterman on 28/03/2021.
//
// example https://developer.apple.com/forums/thread/90531

import Foundation
import EonilFSEvents
import UserNotifications

struct DirectoryMonitor {

    let k = NSObject()
    static let shared = DirectoryMonitor()

    let objUserDefaults = UserDefaults(suiteName: "FileWatch.kloosterman.eu")
    
    var paths: [String] = [""]
    var arrDirectory: [[String : String]] = [["directory":"/tmp/", "count":"0", "enable":"0"]]
    
    init() {
        self.setArrDirectory()
    }
    
    mutating func setArrDirectory() {
        if self.objUserDefaults?.value(forKey: "directory") != nil {
            self.arrDirectory = self.objUserDefaults?.value(forKey: "directory") as! [[String : String]]
        }
    }
    
    mutating func setPaths() {
        self.paths.removeAll()
        
        self.setArrDirectory()
        
        for (item) in self.arrDirectory {
            if (item["enable"] == "1") {
                self.paths.append(item["directory"]!)
            }
        }
        
        debugPrint(self.paths)
    }
    
    func saveLastMessage(_ array: [String], filePath:String) {
        let objUserDefaults = UserDefaults(suiteName: "FileWatch.kloosterman.eu")
        objUserDefaults?.setValue(array, forKey: "lastMessage")
        objUserDefaults?.setValue(filePath, forKey: "lastFilePath")
    }
    
    func stop() {
        EonilFSEvents.stopWatching(for: ObjectIdentifier(k))
    }
    
    func start() {
        debugPrint("started...")
        do {
            try EonilFSEvents.startWatching(
                paths: self.paths,
                for: ObjectIdentifier(k),
                with: process)
        } catch {
            print(error)
        }
    }
    
    private func process(fileSystemEvent e: EonilFSEventsEvent) {
        
        var print_string:String=""
        
        if (e.flag?.contains(EonilFSEventsEventFlags.itemIsDir))!{
            print_string="Dir[\(e.path)]"
        }
        else if (e.flag?.contains(EonilFSEventsEventFlags.itemIsFile))!{
            print_string="File[\(e.path)]"
        }
        
        if (e.flag?.contains(EonilFSEventsEventFlags.itemCreated))!{
            print_string+=" CREATE!"
            let string:String = "\(e.path) is created."
            showNotification(string)
        }
        else if (e.flag?.contains(EonilFSEventsEventFlags.itemRenamed))!{
            print_string+=" RENAMED!"
        }
        else if (e.flag?.contains(EonilFSEventsEventFlags.itemModified))!{
            print_string+=" MODIFIED!"
            let strOutput = readFile(e.path)
            let string:String = "\(e.path) is modified.\n \(strOutput)"
            showNotification(string)
        }
        else if (e.flag?.contains(EonilFSEventsEventFlags.itemRemoved))!{
            print_string+=" REMOVED!"
        }
        
//        print(print_string)
    }
    
    
    func showNotification(_ line: String) -> Void {
        //Step 1.
        let nc = UNUserNotificationCenter.current()
        nc.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted {
                //print("Yes granted...")
            } else {
                //print("Not Granted")
            }
        }
        
        // Step 2. content
        let content = UNMutableNotificationContent()
        //content.title = "Change"
        content.body = line
        content.sound = UNNotificationSound.default
        
        // Step 3. trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        // Step 4. request
        let strUuid = UUID().uuidString
        let request = UNNotificationRequest(identifier: strUuid, content: content, trigger: trigger)
        
        // Step 5. add
        nc.add(request) { (error) in
            // Check error
        }
    }
    
    func readFile(_ file: String) -> String {
        var strReturn: String = ""
        let fileURL = URL(fileURLWithPath: file)
        var arrLastMessage: [String] = []
        
        do {
            let savedData = try Data(contentsOf: fileURL)
            
            if let savedString = String(data: savedData, encoding: .utf8) {
                let myStrings = savedString.components(separatedBy: .newlines)
                for strLine in myStrings.reversed() {
                    arrLastMessage.append(strLine)
                    let regex = try NSRegularExpression(pattern: "[0-9]{4}-[0-9]{2}-[0-9]{2}")
                    if regex.matches(strLine) {
                        strReturn = strLine
                        saveLastMessage(arrLastMessage.reversed(), filePath:fileURL.path)
                        
                        break
                    }
                }
            }
            
        } catch {
            print(error)
        }
        
        return strReturn
    }
}

extension NSRegularExpression {
    func matches(_ string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: [], range: range) != nil
    }
}
