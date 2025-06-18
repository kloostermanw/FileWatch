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
    
    // Message history data
    private var messageHistory: [[String]] = []
    private var currentMessageIndex: Int = 0
    private var isPinned: Bool = false
    
    // UI Controls
    private var pinButton: NSButton!
    private var prevButton: NSButton!
    private var nextButton: NSButton!
    private var controlsView: NSView!
    
    override func loadView() {
        // Create a completely new view structure
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 450, height: 300))
        
        // Create the control view
        controlsView = NSView(frame: NSRect(x: 0, y: contentView.frame.height - 40, width: contentView.frame.width, height: 40))
        controlsView.wantsLayer = true
        controlsView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        controlsView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create the buttons
        pinButton = NSButton(frame: NSRect(x: 10, y: 5, width: 80, height: 30))
        pinButton.title = "Pin"
        pinButton.bezelStyle = .rounded
        pinButton.setButtonType(.toggle)
        pinButton.state = .off
        pinButton.target = self
        pinButton.action = #selector(togglePin(_:))
        pinButton.translatesAutoresizingMaskIntoConstraints = false
        
        prevButton = NSButton(frame: NSRect(x: controlsView.frame.width - 180, y: 5, width: 80, height: 30))
        prevButton.title = "< Prev"
        prevButton.bezelStyle = .rounded
        prevButton.target = self
        prevButton.action = #selector(showPreviousMessage(_:))
        prevButton.translatesAutoresizingMaskIntoConstraints = false
        
        nextButton = NSButton(frame: NSRect(x: controlsView.frame.width - 90, y: 5, width: 80, height: 30))
        nextButton.title = "Next >"
        nextButton.bezelStyle = .rounded
        nextButton.target = self
        nextButton.action = #selector(showNextMessage(_:))
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Create a scroll view for the text
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height - 40))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create the text view
        messageTextView = NSTextView(frame: NSRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height))
        messageTextView.isEditable = false
        messageTextView.isSelectable = true
        messageTextView.textColor = NSColor.white
        messageTextView.backgroundColor = NSColor.textBackgroundColor
        messageTextView.font = NSFont.systemFont(ofSize: 12)
        messageTextView.delegate = self
        messageTextView.autoresizingMask = [.width, .height]
        messageTextView.textContainerInset = NSSize(width: 5, height: 5)
        
        // Add the text view to the scroll view
        scrollView.documentView = messageTextView
        
        // Add buttons to the control view
        controlsView.addSubview(pinButton)
        controlsView.addSubview(prevButton)
        controlsView.addSubview(nextButton)
        
        // Add the scroll view and control view to the content view
        contentView.addSubview(scrollView)
        contentView.addSubview(controlsView)
        
        // Set up constraints for the control view
        NSLayoutConstraint.activate([
            controlsView.topAnchor.constraint(equalTo: contentView.topAnchor),
            controlsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            controlsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            controlsView.heightAnchor.constraint(equalToConstant: 40),
            
            pinButton.leadingAnchor.constraint(equalTo: controlsView.leadingAnchor, constant: 10),
            pinButton.centerYAnchor.constraint(equalTo: controlsView.centerYAnchor),
            
            nextButton.trailingAnchor.constraint(equalTo: controlsView.trailingAnchor, constant: -10),
            nextButton.centerYAnchor.constraint(equalTo: controlsView.centerYAnchor),
            
            prevButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -10),
            prevButton.centerYAnchor.constraint(equalTo: controlsView.centerYAnchor)
        ])
        
        // Set up constraints for the scroll view
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: controlsView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        self.view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        // Load message history
        if objUserDefaults?.value(forKey: "messageHistory") != nil {
            messageHistory = objUserDefaults?.value(forKey: "messageHistory") as! [[String]]
        }
        
        let regex = try! NSRegularExpression(pattern: "[a-zA-Z\\_\\.]+$", options: NSRegularExpression.Options.caseInsensitive)
        let range = NSMakeRange(0, lastFilePath.count)
        let modPath = regex.stringByReplacingMatches(in: lastFilePath, options: [], range: range, withTemplate: "")
        
        let intArrIndex = self.find(value: modPath, in: arrDirectory);
        
        
        if intArrIndex >= 0 && intArrIndex < arrDirectory.count {
            self.local = arrDirectory[intArrIndex]["local"] ?? "/"
            self.remote = arrDirectory[intArrIndex]["remote"] ?? "/"
        }
                
        if objUserDefaults?.value(forKey: "lastMessage") != nil {
            let arrMessage = objUserDefaults?.value(forKey: "lastMessage") as! [String]
            
            // Add message to history if it's not already there
            if !messageHistory.contains(arrMessage) {
                messageHistory.append(arrMessage)
                objUserDefaults?.setValue(messageHistory, forKey: "messageHistory")
            }
            
            // Set current index to the last message
            currentMessageIndex = messageHistory.count - 1
            
            // Display the message
            let attributedText = self.reFormatText(arrMessage.joined(separator: "\n"))
            messageTextView.textStorage?.setAttributedString(attributedText)
            
            // Update navigation buttons
            updateNavigationButtons()
        }
    }
    
    private func updateNavigationButtons() {
        prevButton.isEnabled = currentMessageIndex > 0
        nextButton.isEnabled = currentMessageIndex < messageHistory.count - 1
    }
    
    @objc func togglePin(_ sender: NSButton) {
        isPinned = sender.state == .on
        
        // Get the popover that contains this view controller
        if let popover = self.view.window?.value(forKey: "popover") as? NSPopover {
            popover.behavior = isPinned ? .applicationDefined : .transient
        }
    }
    
    @objc func showPreviousMessage(_ sender: NSButton) {
        if currentMessageIndex > 0 {
            currentMessageIndex -= 1
            displayCurrentMessage()
        }
    }
    
    @objc func showNextMessage(_ sender: NSButton) {
        if currentMessageIndex < messageHistory.count - 1 {
            currentMessageIndex += 1
            displayCurrentMessage()
        }
    }
    
    private func displayCurrentMessage() {
        if currentMessageIndex >= 0 && currentMessageIndex < messageHistory.count {
            let message = messageHistory[currentMessageIndex]
            let attributedText = self.reFormatText(message.joined(separator: "\n"))
            messageTextView.textStorage?.setAttributedString(attributedText)
            updateNavigationButtons()
        }
    }
    
    func find(value searchValue: String, in array: [[String : String]]) -> Int
    {
        
        for (index, value) in array.enumerated() {
            
            for item in value {
                if (item.key == "directory") {
                    if (searchValue.starts(with: item.value)) {
                        return index;
                    }
                };
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

        var regex = try? NSRegularExpression(pattern: "(\\/[a-zA-Z0-9\\/]+\\.php)[\\(\\:]([0-9]+)\\)")
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
