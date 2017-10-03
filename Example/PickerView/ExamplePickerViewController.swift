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
        case numbers(Int, Int), names(Int, Int) // NOTE: (Int, Int) represent the rawValue's of PickerView style enums.
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
    
    var presentationType = PresentationType.numbers(0, 0)
    
    var currentSelectedValue: String?
    var updateSelectedValue: ((_ newSelectedValue: String) -> Void)?
    
    var itemsType: PickerExamplesTableViewController.ItemsType = .label
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar()
        configureExamplePicker()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    // MARK: - Configure Subviews
    
    fileprivate func configureNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
    }
    
    fileprivate func configureExamplePicker() {
        examplePicker.dataSource = self
        examplePicker.delegate = self
        
        let scrollingStyle: PickerView.ScrollingStyle
        let selectionStyle: PickerView.SelectionStyle
        
        switch presentationType {
        case let .numbers(scrollingStyleRaw, selectionStyleRaw):
            scrollingStyle = PickerView.ScrollingStyle(rawValue: scrollingStyleRaw)!
            selectionStyle = PickerView.SelectionStyle(rawValue: selectionStyleRaw)!
            
            examplePicker.scrollingStyle = scrollingStyle
            examplePicker.selectionStyle = selectionStyle
            
            if let currentSelected = currentSelectedValue, let indexOfCurrentSelectedValue = numbers.index(of: currentSelected) {
                examplePicker.currentSelectedRow = indexOfCurrentSelectedValue
            }
        case let .names(scrollingStyleRaw, selectionStyleRaw):
            scrollingStyle = PickerView.ScrollingStyle(rawValue: scrollingStyleRaw)!
            selectionStyle = PickerView.SelectionStyle(rawValue: selectionStyleRaw)!
            
            examplePicker.scrollingStyle = scrollingStyle
            examplePicker.selectionStyle = selectionStyle
            
            if let currentSelected = currentSelectedValue, let indexOfCurrentSelectedValue = osxNames.index(of: currentSelected) {
                examplePicker.currentSelectedRow = indexOfCurrentSelectedValue
            }
        }
        
        if selectionStyle == .image {
            examplePicker.selectionImageView.image = UIImage(named: "SelectionImage")!
        }
    }
    
    // MARK: Actions
    
    @IBAction func close(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func setNewPickerValue(_ sender: UIBarButtonItem) {
        if let updateValue = updateSelectedValue, let currentSelected = currentSelectedValue {
            updateValue(currentSelected)
        }
        
        dismiss(animated: true, completion: nil)
    }
}

extension ExamplePickerViewController: PickerViewDataSource {
    
    // MARK: - PickerViewDataSource
    
    func pickerViewNumberOfRows(_ pickerView: PickerView) -> Int {
        switch presentationType {
        case .numbers(_, _):
            return numbers.count
        case .names(_, _):
            return osxNames.count
        }
    }
    
    func pickerView(_ pickerView: PickerView, titleForRow row: Int, index: Int) -> String {
        switch presentationType {
        case .numbers(_, _):
            return numbers[index]
        case .names(_, _):
            return osxNames[index]
        }
    }
    
}

extension ExamplePickerViewController: PickerViewDelegate {
    
    // MARK: - PickerViewDelegate
    
    func pickerViewHeightForRows(_ pickerView: PickerView) -> CGFloat {
        return 50.0
    }
    
    func pickerView(_ pickerView: PickerView, didSelectRow row: Int, index: Int) {
        switch presentationType {
        case .numbers(_, _):
            currentSelectedValue = numbers[index]
        case .names(_, _):
            currentSelectedValue = osxNames[index]
        }

        print(currentSelectedValue ?? "")
    }
    
    func pickerView(_ pickerView: PickerView, styleForLabel label: UILabel, highlighted: Bool) {
        label.textAlignment = .center
        if #available(iOS 8.2, *) {
            if (highlighted) {
                label.font = UIFont.systemFont(ofSize: 26.0, weight: UIFont.Weight.light)
            } else {
                label.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.light)
            }
        } else {
            if (highlighted) {
                label.font = UIFont(name: "HelveticaNeue-Light", size: 16.0)
            } else {
                label.font = UIFont(name: "HelveticaNeue-Light", size: 26.0)
            }
        }
        
        if (highlighted) {
            label.textColor = view.tintColor
        } else {
            label.textColor = UIColor(red: 161.0/255.0, green: 161.0/255.0, blue: 161.0/255.0, alpha: 1.0)
        }
    }
    
    func pickerView(_ pickerView: PickerView, viewForRow row: Int, index: Int, highlighted: Bool, reusingView view: UIView?) -> UIView? {
        
        if (itemsType != .customView) {
            return nil
        }
        
        var customView = view
        
        let imageTag = 100
        let labelTag = 101
        
        if (customView == nil) {
            var frame = pickerView.frame
            frame.origin = CGPoint.zero
            frame.size.height = 50
            customView = UIView(frame: frame)
            
            let imageView = UIImageView(frame: frame)
            imageView.tag = imageTag
            imageView.contentMode = .scaleAspectFill
            imageView.image = UIImage(named: "AbstractImage")
            imageView.clipsToBounds = true
            
            customView?.addSubview(imageView)
            
            let label = UILabel(frame: frame)
            label.tag = labelTag
            label.textColor = UIColor.white
            label.shadowColor = UIColor.black
            label.shadowOffset = CGSize(width: 1.0, height: 1.0)
            label.textAlignment = .center
            
            if #available(iOS 8.2, *) {
                label.font = UIFont.systemFont(ofSize: 26.0, weight: UIFont.Weight.light)
            } else {
                label.font = UIFont(name: "HelveticaNeue-Light", size: 26.0)
            }
            
            customView?.addSubview(label)
        }
        
        let imageView = customView?.viewWithTag(imageTag) as? UIImageView
        let label = customView?.viewWithTag(labelTag) as? UILabel
        
        switch presentationType {
        case .numbers(_, _):
            label?.text = numbers[index]
        case .names(_, _):
            label?.text = osxNames[index]
        }
        
        let alpha: CGFloat = highlighted ? 1.0 : 0.5
        
        imageView?.alpha = alpha
        label?.alpha = alpha
        
        return customView
    }
    
}
