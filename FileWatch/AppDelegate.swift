//
//  AppDelegate.swift
//  FileWatch
//
//  Created by Wiebe Kloosterman on 27/03/2021.
//

import Cocoa
import EonilFSEvents

@main
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let updates = UpdateController()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard let logo = NSImage(named: NSImage.Name("search-plus-solid")) else { return }
        
        let resizedLogo = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { (dstRect) -> Bool in
                logo.draw(in: dstRect)
                return true
            }
        resizedLogo.isTemplate = true
        
        statusItem.button?.image = resizedLogo

        let statusBarMenu = NSMenu(title: "Cap Status Bar Menu")
        statusItem.menu = statusBarMenu
        
        statusBarMenu.addItem(
            withTitle: "Latest message",
            action: #selector(showMessage),
            keyEquivalent: "")
        
        statusBarMenu.addItem(
            withTitle: "Settings",
            action: #selector(showSettings),
            keyEquivalent: "")

        statusBarMenu.addItem(
            withTitle: "Check for Updates…",
            action: #selector(checkForUpdates),
            keyEquivalent: "")

        statusBarMenu.addItem(
            withTitle: "Stop application",
            action: #selector(exit),
            keyEquivalent: "")

        var objDmon = DirectoryMonitor.shared
        objDmon.setPaths()
        objDmon.start()

        updates.start()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc func exit() {
        NSApplication.shared.terminate(self)
    }

    @objc func checkForUpdates() {
        updates.checkForUpdates()
    }

    @objc func showSettings() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateController(withIdentifier: "ViewController") as? ViewController else {
            fatalError("Unable to find ViewController.")
        }
        
        let popoverView = NSPopover()
        popoverView.contentViewController = vc
        popoverView.behavior = .transient
        vc.popover = popoverView
        popoverView.show(relativeTo: statusItem.button!.bounds, of: statusItem.button!, preferredEdge: .maxY)
    }

    @objc func showMessage() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateController(withIdentifier: .init(stringLiteral: "messageID")) as? MessageViewController else { return }

        let popoverView = NSPopover()
        popoverView.contentViewController = vc
        popoverView.behavior = .transient
        popoverView.contentSize = NSSize(width: 450, height: 300)
        
        // Store reference to popover in the view controller for resize functionality
        vc.popover = popoverView
        
        popoverView.show(relativeTo: statusItem.button!.bounds, of: statusItem.button!, preferredEdge: .maxY)
    }
}
