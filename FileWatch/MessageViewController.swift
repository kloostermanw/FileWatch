//
//  MessageViewController.swift
//  FileWatch
//
//  Created by Wiebe Kloosterman on 10/04/2021.
//

import Cocoa

class MessageViewController: NSViewController, NSTextViewDelegate {
    
    @IBOutlet var messageTextView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageTextView.delegate = self
        
        messageTextView.string = "no Content."
        
        let objUserDefaults = UserDefaults(suiteName: "FileWatch.kloosterman.eu")
        if objUserDefaults?.value(forKey: "lastMessage") != nil {
            let arrMessage = objUserDefaults?.value(forKey: "lastMessage") as! [String]
            let attributedText = self.reFormatText(arrMessage.joined(separator: "\n"))
            messageTextView.textStorage?.setAttributedString(attributedText)
        }

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
            
            let cmd = "phpstorm --line " + line + " " + path
            
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
        print(link)
        
        
        
        return true
    }
}
