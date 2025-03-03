//
//  PartTableViewController.swift
//  ldrawtest
//
//  Created by iain on 27/02/2025.
//

import Cocoa

class PartTableViewController: NSViewController {
    let partsList: [String]
    
    var partSelectionHandler: ((String) -> Void)?
    
    init(withPartsFolder folder: String) {
        do {
            var parts = try FileManager.default.contentsOfDirectory(atPath: folder + "/parts")
            parts.sort()
            
            partsList = parts
        } catch {
            fatalError("Couldn't read parts folder: \(error)")
        }

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let scrollView = NSScrollView()
        view = scrollView
        
        let tableView = NSTableView()
        scrollView.documentView = tableView
        
        let tableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Part"))
        tableView.addTableColumn(tableColumn)
        
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension PartTableViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return partsList.count
    }
}

extension PartTableViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        var cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("Part"),
                                      owner: nil) as? NSTextField
        
        if cell == nil {
            cell = NSTextField(labelWithString: "")
            cell?.identifier = NSUserInterfaceItemIdentifier("Part")
        }
        cell?.stringValue = partsList[row]
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else { return }
        let selectedRow = tableView.selectedRow
        
        if selectedRow >= 0 {
            partSelectionHandler?(partsList[selectedRow])
        }
    }
}
