//
//  PickerExamplesTableViewController.swift
//  FAPickerView
//
//  Created by Filipe Alvarenga on 09/08/15.
//  Copyright (c) 2015 Filipe Alvarenga. All rights reserved.
//

import UIKit
import PickerView

class PickerExamplesTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var scrollingStyleOption: UISegmentedControl!
    @IBOutlet weak var selectionStyleOption: UISegmentedControl!
    
    var pickedNumber: String?
    var pickedOSX: String?
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showNumberPicker" {
            let numberNav = segue.destinationViewController as! UINavigationController
            let numberPicker = numberNav.topViewController as! ExamplePickerViewController
            numberPicker.currentSelectedValue = pickedNumber
            numberPicker.presentationType = ExamplePickerViewController.PresentationType.Numbers(scrollingStyleOption.selectedSegmentIndex,
                                                                                                 selectionStyleOption.selectedSegmentIndex)
            numberPicker.updateSelectedValue = { (newSelectedValue) in
                self.pickedNumber = newSelectedValue
                self.tableView.reloadData()
            }
        }
        
        if segue.identifier == "showNamePicker" {
            let osxNav = segue.destinationViewController as! UINavigationController
            let osxPicker = osxNav.topViewController as! ExamplePickerViewController
            osxPicker.currentSelectedValue = pickedOSX
            osxPicker.presentationType = ExamplePickerViewController.PresentationType.Names(scrollingStyleOption.selectedSegmentIndex,
                                                                                            selectionStyleOption.selectedSegmentIndex)
            osxPicker.updateSelectedValue = { (newSelectedValue) in
                self.pickedOSX = newSelectedValue
                self.tableView.reloadData()
            }
        }
    }
    
}

extension PickerExamplesTableViewController {

    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch (section) {
        case 1:
            return pickedNumber != nil ? "You picked the number \(pickedNumber!)." : "You don't picked any number."
        case 2:
            return pickedOSX != nil ? "You picked the OS X \(pickedOSX!)." : "You don't picked any OS X."
        default:
            return "You can also set a custom apperance for the text in two different states (regular and highlighted) through FAPickerViewDelegate methods."
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 1:
            performSegueWithIdentifier("showNumberPicker", sender: self)
        case 2:
            performSegueWithIdentifier("showNamePicker", sender: self)
        default:
            break
        }
    }
    
}