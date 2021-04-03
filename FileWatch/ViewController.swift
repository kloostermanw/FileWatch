//
//  ViewController.swift
//  FileWatch
//
//  Created by Wiebe Kloosterman on 27/03/2021.
//

import Cocoa

class ViewController: NSViewController {

    let objUserDefaults = UserDefaults(suiteName: "FileWatch.kloosterman.eu")
    var arrDirectory: [[String : String]] = [["directory":"/tmp", "count":"0", "enable":"1"]]
    
    @IBOutlet weak var directoryTableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if objUserDefaults?.value(forKey: "directory") != nil {
            arrDirectory = objUserDefaults?.value(forKey: "directory") as! [[String : String]]
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func ExitNow(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func AddButton(_ sender: Any) {
        let objDirectorySelector: NSOpenPanel = NSOpenPanel()
        objDirectorySelector.canChooseDirectories = true
        objDirectorySelector.canChooseFiles = false
        objDirectorySelector.allowsMultipleSelection = false
        
        objDirectorySelector.runModal()
        var strChosenDir: String = objDirectorySelector.url!.absoluteString
        strChosenDir = strChosenDir.replacingOccurrences(of: "file://", with: "")

        if (strChosenDir != "") {
            arrDirectory.append(
                [
                    "directory":strChosenDir,
                    "count":"0",
                    "enable":"0"
                ]
            )
            objUserDefaults?.setValue(arrDirectory, forKey: "directory")
        }
    }
    
    func reload() {
        var objDmon = DirectoryMonitor.shared
        objDmon.setPaths()
        objDmon.stop()
        objDmon.start()
    }
}

extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrDirectory.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let userCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "userCell"), owner: self) as? CustomTableCell else { return nil }
        
        userCell.DirectoryLabel.stringValue = arrDirectory[row]["directory"] ?? "unknown directory"
        userCell.countLabel.stringValue = arrDirectory[row]["count"] ?? "unknown directory"
        
        let intEnable = Int(arrDirectory[row]["enable"]!)
        
        userCell.enableCheckBox.state = NSControl.StateValue(rawValue: intEnable!)

        return userCell
    }
    
    @IBAction func delIssue(_ sender: NSButton)
    {
        let row = directoryTableView.row(for: sender)
        arrDirectory.remove(at: row)
        directoryTableView.removeRows(at: IndexSet(integer: row), withAnimation: .effectFade)
        
        objUserDefaults?.setValue(arrDirectory, forKey: "directory")
        reload()
    }
    
    @IBAction func checkIssue(_ sender: NSButton)
    {
        let row = directoryTableView.row(for: sender)
        
        if (arrDirectory[row]["enable"] == "1") {
            arrDirectory[row]["enable"] = "0"
        } else {
            arrDirectory[row]["enable"] = "1"
        }

        objUserDefaults?.setValue(arrDirectory, forKey: "directory")
        reload()
    }
}
