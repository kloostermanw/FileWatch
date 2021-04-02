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

class DirectoryMonitor {

    static let shared = DirectoryMonitor()

    let objUserDefaults = UserDefaults(suiteName: "FileWatch.kloosterman.eu")
    
    var paths: [String] = [""]
    var arrDirectory: [[String : String]] = [["directory":"/tmp/", "count":"0", "enable":"0"]]
    
    init() {
        self.setArrDirectory()
    }
    
    func setArrDirectory() {
        if self.objUserDefaults?.value(forKey: "directory") != nil {
            self.arrDirectory = self.objUserDefaults?.value(forKey: "directory") as! [[String : String]]
        }
    }
    
    func setPaths() {
        self.paths.removeAll()
        
        self.setArrDirectory()
        
        for (item) in self.arrDirectory {
            self.paths.append(item["directory"]!)
        }
        
        debugPrint(self.paths)
    }
    
    func stop() {
        EonilFSEvents.stopWatching(for: ObjectIdentifier(self))
    }
    
    func start() {
        debugPrint("started...")
        do {
            try EonilFSEvents.startWatching(
                paths: self.paths,
                for: ObjectIdentifier(self),
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
        }
        else if (e.flag?.contains(EonilFSEventsEventFlags.itemRenamed))!{
            print_string+=" RENAMED!"
        }
        else if (e.flag?.contains(EonilFSEventsEventFlags.itemModified))!{
            print_string+=" MODIFIED!"
        }
        else if (e.flag?.contains(EonilFSEventsEventFlags.itemRemoved))!{
            print_string+=" REMOVED!"
        }
        
        print(print_string)
        showNotification(print_string)
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
        
        // Step 2.
        let content = UNMutableNotificationContent()
        content.title = "Change"
        content.body = line
        
        // Step 3.
        var dateComponents = DateComponents()
        dateComponents.hour = 13
        dateComponents.minute = 54
//        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        
        
        // Step 4.
        let strUuid = UUID().uuidString
        
        let request = UNNotificationRequest(identifier: strUuid, content: content, trigger: trigger)
        
        
        // Step 5.
        nc.add(request) { (error) in
            // Check error
        }
    }
}
