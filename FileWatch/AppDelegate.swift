//
//  AppDelegate.swift
//  FileWatch
//
//  Created by Wiebe Kloosterman on 27/03/2021.
//

import Cocoa
import EonilFSEvents

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard let logo = NSImage(named: NSImage.Name("search-plus-solid")) else { return }
        
        let resizedLogo = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { (dstRect) -> Bool in
                logo.draw(in: dstRect)
                return true
            }
        resizedLogo.isTemplate = true
        
        statusItem.button?.image = resizedLogo
        statusItem.button?.target = self
        statusItem.button?.action = #selector(showSettings)
        
        var objDmon = DirectoryMonitor.shared
        objDmon.setPaths()
        objDmon.start()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc func showSettings() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateController(withIdentifier: "ViewController") as? ViewController else {
            fatalError("Unable to find ViewController.")
        }
        
        let popoverView = NSPopover()
        popoverView.contentViewController = vc
        popoverView.behavior = .transient
        popoverView.show(relativeTo: statusItem.button!.bounds, of: statusItem.button!, preferredEdge: .maxY)
    }
}
