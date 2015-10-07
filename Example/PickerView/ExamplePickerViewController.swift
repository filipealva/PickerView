//
//  NumberPickerViewController.swift
//  PickerView
//
//  Created by Filipe Alvarenga on 09/08/15.
//  Copyright (c) 2015 Filipe Alvarenga. All rights reserved.
//

import UIKit
import PickerView

class ExamplePickerViewController: UIViewController {

    // MARK: - Nested Types

    enum PresentationType {
        case Numbers(Int, Int), Names(Int, Int) // NOTE: (Int, Int) represent the rawValue's of PickerView style enums.
    }

    // MARK: - Properties

    @IBOutlet weak var examplePicker: PickerView!
    
    let numbers: [String] = {
        var numbers = [String]()
        
        for index in 1...10 {
            numbers.append(String(index))
        }
    
        return numbers
    }()
    
    let osxNames = ["Cheetah", "Puma", "Jaguar", "Panther", "Tiger", "Leopard", "Snow Leopard", "Lion", "Montain Lion",
                    "Mavericks", "Yosemite", "El Capitan"]
    
    var presentationType = PresentationType.Numbers(0, 0)
    
    var currentSelectedValue: String?
    var updateSelectedValue: ((newSelectedValue: String) -> Void)?
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar()
        configureExamplePicker()
    }
    
    // MARK: - Configure Subviews
    
    private func configureNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.translucent = true
    }
    
    private func configureExamplePicker() {
        examplePicker.dataSource = self
        examplePicker.delegate = self
        
        let scrollingStyle: PickerView.ScrollingStyle
        let selectionStyle: PickerView.SelectionStyle
        
        switch presentationType {
        case let .Numbers(scrollingStyleRaw, selectionStyleRaw):
            scrollingStyle = PickerView.ScrollingStyle(rawValue: scrollingStyleRaw)!
            selectionStyle = PickerView.SelectionStyle(rawValue: selectionStyleRaw)!
            
            examplePicker.scrollingStyle = scrollingStyle
            examplePicker.selectionStyle = selectionStyle
            
            if let currentSelected = currentSelectedValue, indexOfCurrentSelectedValue = numbers.indexOf(currentSelected) {
                examplePicker.currentSelectedRow = indexOfCurrentSelectedValue
            }
        case let .Names(scrollingStyleRaw, selectionStyleRaw):
            scrollingStyle = PickerView.ScrollingStyle(rawValue: scrollingStyleRaw)!
            selectionStyle = PickerView.SelectionStyle(rawValue: selectionStyleRaw)!
            
            examplePicker.scrollingStyle = scrollingStyle
            examplePicker.selectionStyle = selectionStyle
            
            if let currentSelected = currentSelectedValue, indexOfCurrentSelectedValue = osxNames.indexOf(currentSelected) {
                examplePicker.currentSelectedRow = indexOfCurrentSelectedValue
            }
        }
        
        if selectionStyle == .Image {
            examplePicker.selectionImageView.image = UIImage(named: "SelectionImage")!
        }
    }
    
    // MARK: Actions
    
    @IBAction func close(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func setNewPickerValue(sender: UIBarButtonItem) {
        if let updateValue = updateSelectedValue, currentSelected = currentSelectedValue {
            updateValue(newSelectedValue: currentSelected)
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}

extension ExamplePickerViewController: PickerViewDataSource {
    
    // MARK: - PickerViewDataSource
    
    func numberOfRowsInPickerView(pickerView: PickerView) -> Int {
        switch presentationType {
        case .Numbers(_, _):
            return numbers.count
        case .Names(_, _):
            return osxNames.count
        }
    }
    
    func pickerView(pickerView: PickerView, titleForRow row: Int) -> String {
        switch presentationType {
        case .Numbers(_, _):
            return numbers[row]
        case .Names(_, _):
            return osxNames[row]
        }
    }
    
}

extension ExamplePickerViewController: PickerViewDelegate {
    
    // MARK: - PickerViewDelegate
    
    func heightForRowInPickerView(pickerView: PickerView) -> CGFloat {
        return 50.0
    }
    
    func pickerView(pickerView: PickerView, didSelectRow row: Int) {
        switch presentationType {
        case .Numbers(_, _):
            currentSelectedValue = numbers[row]
        case .Names(_, _):
            currentSelectedValue = osxNames[row]
        }

        print(currentSelectedValue)
    }
    
    func styleForLabel(label: UILabel, inPickerView pickerView: PickerView) {
        label.textAlignment = .Center
        if #available(iOS 8.2, *) {
            label.font = UIFont.systemFontOfSize(16.0, weight: UIFontWeightLight)
        } else {
            label.font = UIFont(name: "HelveticaNeue-Light", size: 16.0)
        }
        label.textColor = UIColor(red: 161.0/255.0, green: 161.0/255.0, blue: 161.0/255.0, alpha: 1.0)
    }
    
    func styleForHighlightedLabel(label: UILabel, inPickerView pickerView: PickerView) {
        label.textAlignment = .Center
        if #available(iOS 8.2, *) {
            label.font = UIFont.systemFontOfSize(26.0, weight: UIFontWeightLight)
        } else {
            label.font = UIFont(name: "HelveticaNeue-Light", size: 26.0)
        }
        label.textColor = view.tintColor
    }
    
}
