//
//  MessageViewController.swift
//  FileWatch
//
//  Created by Wiebe Kloosterman on 10/04/2021.
//

import Cocoa

class MessageViewController: NSViewController, NSTextViewDelegate {
    
    @IBOutlet var messageTextView: NSTextView!
    var local: String = "/"
    var remote: String = "/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageTextView.delegate = self
        var arrDirectory: [[String : String]] = [["directory":"/tmp", "count":"0", "enable":"1", "local":"/", "remote":"/"]]
        var lastFilePath: String = ""
        
        messageTextView.string = "no Content."
        let objUserDefaults = UserDefaults(suiteName: "FileWatch.kloosterman.eu")
        
        if objUserDefaults?.value(forKey: "lastFilePath") != nil {
            lastFilePath = objUserDefaults?.value(forKey: "lastFilePath") as! String
        }
        
        if objUserDefaults?.value(forKey: "directory") != nil {
            arrDirectory = objUserDefaults?.value(forKey: "directory") as! [[String : String]]
        }
        
        let regex = try! NSRegularExpression(pattern: "[a-zA-Z\\_\\.]+$", options: NSRegularExpression.Options.caseInsensitive)
        let range = NSMakeRange(0, lastFilePath.count)
        let modPath = regex.stringByReplacingMatches(in: lastFilePath, options: [], range: range, withTemplate: "")
        
        let intArrIndex = self.find(value: modPath, in: arrDirectory);
        
        local = arrDirectory[intArrIndex]["local"] ?? "/"
        remote = arrDirectory[intArrIndex]["remote"] ?? "/"
                
        if objUserDefaults?.value(forKey: "lastMessage") != nil {
            let arrMessage = objUserDefaults?.value(forKey: "lastMessage") as! [String]
            let attributedText = self.reFormatText(arrMessage.joined(separator: "\n"))
            messageTextView.textStorage?.setAttributedString(attributedText)
        }
    }
    
    func find(value searchValue: String, in array: [[String : String]]) -> Int
    {
        for (index, value) in array.enumerated() {
            if value["directory"] == searchValue {
                return index
            }
        }

        return 999999999999999
    }
    
    func reFormatText(_ strLine:String) -> NSMutableAttributedString {
        
        let range = NSMakeRange(0, strLine.count)
        
        let attrString = NSMutableAttributedString(string: strLine, attributes: [
            NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12),
            NSAttributedString.Key.foregroundColor: NSColor.white,
        ]);
        
        //attrString.addAttribute(.font, value: NSFont.systemFont(ofSize: 8), range: NSRange(location: 0, length: 10))

        var regex = try? NSRegularExpression(pattern: "(\\/[a-zA-Z\\/]+\\.php)[\\(\\:]([0-9]+)\\)")
        var matches = (regex?.matches(in: strLine, options: [], range: range))!
        
        for match in matches {
            attrString.addAttribute(.foregroundColor, value: NSColor.systemRed, range: match.range(at: 1))
            
            let line = getRangeFromString(string: strLine, range: match.range(at: 2))
            let path = getRangeFromString(string: strLine, range: match.range(at: 1))
            
            let newPath = path.replacingOccurrences(of: remote, with: local)
            
            let cmd = line + ":" + newPath
            
            attrString.addAttribute(NSAttributedString.Key.link, value: cmd, range: match.range(at: 1))
        }
        
        regex = try? NSRegularExpression(pattern: "\\[stacktrace\\]")
        matches = (regex?.matches(in: strLine, options: [], range: range))!
        for match in matches {
            //attrString.addAttribute(.font, value: NSFont.systemFont(ofSize: 8), range: match.range)
            //attrString.addAttribute(.foregroundColor, value: NSColor.systemRed, range: match.range)
            if let swiftRange = Range(match.range, in: strLine) {
                let name = strLine[swiftRange]
                attrString.replaceCharacters(in: match.range, with: "\n" + name)
            }
        }

        return attrString
    }
    
    func getRangeFromString(string: String, range: NSRange) -> String {
        var strReturn: String = ""
        
        if let swiftRange = Range(range, in: string) {
            strReturn = String(string[swiftRange])
        }
        
        return strReturn
    }
    
    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        //print(link)
        let linkArr = (link as AnyObject).components(separatedBy: ":")
                
        let arrArgs: [String] = ["-na", "PhpStorm.app", "--args", "--line", linkArr[0], linkArr[1]]
        
        
        try self.execCommand(command: "/usr/bin/open", args: arrArgs)
        
        return true
    }
    
    func execCommand(command: String, args: [String]) {
        let task = Process()

        //the path to the external program you want to run
        let executableURL = URL(fileURLWithPath: command)
        task.executableURL = executableURL

        //use pipe to get the execution program's output
        let pipe = Pipe()
        task.standardOutput = pipe

        //this one helps set the directory the executable operates from
        task.currentDirectoryURL = URL(fileURLWithPath: "/")

        //all the arguments to the executable
        task.arguments = args

        //what to call once the process completes
        task.terminationHandler = {
            _ in
            print("process run complete.")
        }

        try! task.run()
        task.waitUntilExit()

        //all this code helps you capture the output so you can, for e.g., show the user
        let d = pipe.fileHandleForReading.readDataToEndOfFile()
        let ds = String (data: d, encoding: String.Encoding.utf8)
        print("terminal output: \(ds!)")

        print("execution complete...")
    }
}
