//
//  CustomTableCell.swift
//  FileWatch
//
//  Created by Wiebe Kloosterman on 27/03/2021.
//

import Cocoa

class CustomTableCell: NSTableCellView {

    @IBOutlet weak var DirectoryLabel: NSTextField!
    @IBOutlet weak var countLabel: NSTextField!
    @IBOutlet weak var enableCheckBox: NSButton!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        DirectoryLabel.lineBreakMode = .byTruncatingHead
    }
}
