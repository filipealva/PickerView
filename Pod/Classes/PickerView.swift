//
//  PickerView.swift
//
//  Created by Filipe Alvarenga on 19/05/15.
//  Copyright (c) 2015 Filipe Alvarenga. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

// MARK: - Protocols

public protocol PickerViewDataSource: class {
    func numberOfRowsInPickerView(pickerView: PickerView) -> Int
    func pickerView(pickerView: PickerView, titleForRow row:Int) -> String
}

public protocol PickerViewDelegate: class {
    func pickerView(pickerView: PickerView, didSelectRow row: Int)
    func heightForRowInPickerView(pickerView: PickerView) -> CGFloat
    func styleForLabel(label: UILabel, inPickerView pickerView: PickerView)
    func styleForHighlightedLabel(label: UILabel, inPickerView pickerView: PickerView)
}

public class PickerView: UIView {
    
    // MARK: Nested Types
    
    private class SimplePickerTableViewCell: UITableViewCell {
        lazy var titleLabel: UILabel = {
            let titleLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: self.contentView.frame.width, height: self.contentView.frame.height))
            
            return titleLabel
        }()
    }
    
    /**
        ScrollingStyle Enum.
    
        - parameter Default: Show only the number of rows informed in data source.
    
        - parameter Infinite: Loop through the data source offering a infinite scrolling experience to the user.
    */
    
    public enum ScrollingStyle: Int {
        case Default, Infinite
    }
    
    /**
        SelectionStyle Enum.
    
        - parameter None: Don't uses any aditional view to highlight the selection, only the label style customization provided by delegate.
    
        - parameter DefaultIndicator: Provide a simple selection indicator on the bottom of the highlighted row with full width and 2pt of height.
                                  The default color is its superview `tintColor` but you have free access to customize the DefaultIndicator through the `defaultSelectionIndicator` property.
    
        - parameter Overlay: Provide a full width and height (the height you provided on delegate) view that overlay the highlighted row.
                         The default color is its superview `tintColor` and the alpha is set to 0.25, but you have free access to customize it through the `selectionOverlay` property.
                         Tip: You can set the alpha to 1.0 and background color to .clearColor() and add your custom selection view to make it looks as you want 
                         (don't forget to properly add the constraints related to `selectionOverlay` to keep your experience with any screen size).
    
        - parameter Image: Provide a full width and height image view selection indicator (the height you provided on delegate) without any image.
                       You must have a selection indicator as a image and set it to the image view through the `selectionImageView` property.
    */
    
    public enum SelectionStyle: Int {
        case None, DefaultIndicator, Overlay, Image
    }
    
    // MARK: Properties
    
    var enabled = true {
        didSet {
            if enabled {
                turnPickerViewOn()
            } else {
                turnPickerViewOff()
            }
        }
    }
    
    private var selectionOverlayH: NSLayoutConstraint!
    private var selectionImageH: NSLayoutConstraint!
    private var selectionIndicatorB: NSLayoutConstraint!
    private var pickerCellBackgroundColor: UIColor?
    
    var numberOfRowsByDataSource: Int {
        get {
            return dataSource?.numberOfRowsInPickerView(self) ?? 0
        }
    }
    
    var rowHeight: CGFloat {
        get {
            return delegate?.heightForRowInPickerView(self) ?? 0
        }
    }
    
    override public var backgroundColor: UIColor? {
        didSet {
            tableView.backgroundColor = backgroundColor
            pickerCellBackgroundColor = backgroundColor
        }
    }
    
    private let pickerViewCellIdentifier = "pickerViewCell"
    
    public weak var dataSource: PickerViewDataSource?
    public weak var delegate: PickerViewDelegate?
    
    public lazy var defaultSelectionIndicator: UIView = {
        let selectionIndicator = UIView()
        selectionIndicator.backgroundColor = self.tintColor
        selectionIndicator.alpha = 0.0
        
        return selectionIndicator
    }()
    
    public lazy var selectionOverlay: UIView = {
        let selectionOverlay = UIView()
        selectionOverlay.backgroundColor = self.tintColor
        selectionOverlay.alpha = 0.0
        
        return selectionOverlay
    }()
    
    public lazy var selectionImageView: UIImageView = {
        let selectionImageView = UIImageView()
        selectionImageView.alpha = 0.0
        
        return selectionImageView
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        
        return tableView
    }()
    
    private var infinityRowsMultiplier: Int = 1
    public var currentSelectedRow: Int!
    
    private var firstTimeOrientationChanged = true
    private var orientationChanged = false
    private var isScrolling = false
    private var setupHasBeenDone = false
    
    public var scrollingStyle = ScrollingStyle.Default {
        didSet {
            switch scrollingStyle {
            case .Default:
                infinityRowsMultiplier = 1
            case .Infinite:
                infinityRowsMultiplier = generateInfinityRowsMultiplier()
            }
        }
    }
    
    public var selectionStyle = SelectionStyle.None {
        didSet {
            switch selectionStyle {
            case .DefaultIndicator:
                defaultSelectionIndicator.alpha = 1.0
                selectionOverlay.alpha = 0.0
                selectionImageView.alpha = 0.0
            case .Overlay:
                selectionOverlay.alpha = 0.25
                defaultSelectionIndicator.alpha = 0.0
                selectionImageView.alpha = 0.0
            case .Image:
                selectionImageView.alpha = 1.0
                selectionOverlay.alpha = 0.0
                defaultSelectionIndicator.alpha = 0.0
            case .None:
                selectionOverlay.alpha = 0.0
                defaultSelectionIndicator.alpha = 0.0
                selectionImageView.alpha = 0.0
            }
        }
    }
    
    // MARK: Initialization
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // MARK: Subviews Setup
    
    private func setup() {
        infinityRowsMultiplier = generateInfinityRowsMultiplier()
        
        // Setup subviews constraints and apperance
        translatesAutoresizingMaskIntoConstraints = false
        setupTableView()
        setupSelectionOverlay()
        setupSelectionImageView()
        setupDefaultSelectionIndicator()
        
        // Setup UITableView data source & delegate in background
        // Reason: When PickerView scrollingStyle is set to .Infinite and the data source is huge, setting UITableView data source & delegate
        // on main queue can causes a little delay in the transition animation (push or modal animation)
        let priority = DISPATCH_QUEUE_PRIORITY_BACKGROUND
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            self.tableView.delegate = self
            self.tableView.dataSource = self
            
            dispatch_async(dispatch_get_main_queue(),{
                // Some UI Adjustments we need to do after setting UITableView data source & delegate.
                self.configureFirstSelection()
                self.adjustSelectionOverlayHeightConstraint()
            })
        }
    }
    
    private func setupTableView() {
        tableView.backgroundColor = .clearColor()
        tableView.separatorStyle = .None
        tableView.separatorColor = .None
        tableView.allowsSelection = true
        tableView.allowsMultipleSelection = false
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.scrollsToTop = false
        tableView.registerClass(SimplePickerTableViewCell.classForCoder(), forCellReuseIdentifier: pickerViewCellIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tableView)
        
        addSelfRelatedConstraintsOfItem(tableView, withAttributes: [.Height, .Width, .Leading, .Top, .Bottom,  .Trailing])
    }
    
    private func setupSelectionOverlay() {
        selectionOverlay.userInteractionEnabled = false
        selectionOverlay.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selectionOverlay)
        
        selectionOverlayH = NSLayoutConstraint(item: selectionOverlay, attribute: .Height, relatedBy: .Equal, toItem: nil,
                                                attribute: .NotAnAttribute, multiplier: 1, constant: rowHeight)
        addConstraint(selectionOverlayH)
        
        addSelfRelatedConstraintsOfItem(selectionOverlay, withAttributes: [.Width, .Leading, .Trailing, .CenterY])
    }
    
    private func setupSelectionImageView() {
        selectionImageView.userInteractionEnabled = false
        selectionImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selectionImageView)
        
        selectionImageH = NSLayoutConstraint(item: selectionImageView, attribute: .Height, relatedBy: .Equal, toItem: nil,
                                                attribute: .NotAnAttribute, multiplier: 1, constant: rowHeight)
        addConstraint(selectionImageH)
        
        addSelfRelatedConstraintsOfItem(selectionImageView, withAttributes: [.Width, .Leading, .Trailing, .CenterY])
    }
    
    private func setupDefaultSelectionIndicator() {
        defaultSelectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(defaultSelectionIndicator)
        
        let selectionIndicatorH = NSLayoutConstraint(item: defaultSelectionIndicator, attribute: .Height, relatedBy: .Equal, toItem: nil,
                                                        attribute: .NotAnAttribute, multiplier: 1, constant: 2.0)
        addConstraint(selectionIndicatorH)
        
        
        selectionIndicatorB = NSLayoutConstraint(item: defaultSelectionIndicator, attribute: .Bottom, relatedBy: .Equal,
                                                    toItem: self, attribute: .CenterY, multiplier: 1, constant: (rowHeight / 2))
        addConstraint(selectionIndicatorB)
        
        
        addSelfRelatedConstraintsOfItem(defaultSelectionIndicator, withAttributes: [.Width, .Leading, .Trailing])
    }
    
    private func addSelfRelatedConstraintsOfItem(item: AnyObject, withAttributes attributes: [NSLayoutAttribute]) {
        for att in attributes {
            let selectionIndicator = NSLayoutConstraint(item: item, attribute: att, relatedBy: .Equal,
                                                        toItem: self, attribute: att, multiplier: 1, constant: 0)
            addConstraint(selectionIndicator)
        }
    }
    
    // MARK: Infinite Scrolling Helpers
    
    private func generateInfinityRowsMultiplier() -> Int {
        if scrollingStyle == .Default {
            return 1
        }
    
        if numberOfRowsByDataSource > 100 {
            return 100
        } else if numberOfRowsByDataSource < 100 && numberOfRowsByDataSource > 50 {
            return 200
        } else if numberOfRowsByDataSource < 50 && numberOfRowsByDataSource > 25 {
            return 400
        } else {
            return 800
        }
    }
    
    // MARK: Life Cycle
    
    public override func willMoveToWindow(newWindow: UIWindow?) {
        super.willMoveToWindow(newWindow)
        
        if let _ = newWindow {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "adjustCurrentSelectedAfterOrientationChanges",
                                                            name: UIDeviceOrientationDidChangeNotification, object: nil)
        } else {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIDeviceOrientationDidChangeNotification, object: nil)
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if !setupHasBeenDone {
            setup()
            setupHasBeenDone = true
        }
    }
    
    private func adjustSelectionOverlayHeightConstraint() {
        if selectionOverlayH.constant != rowHeight || selectionImageH.constant != rowHeight || selectionIndicatorB.constant != (rowHeight / 2) {
            selectionOverlayH.constant = rowHeight
            selectionImageH.constant = rowHeight
            selectionIndicatorB.constant = -(rowHeight / 2)
            layoutIfNeeded()
        }
    }
    
    func adjustCurrentSelectedAfterOrientationChanges() {
        setNeedsLayout()
        layoutIfNeeded()
        
        // Configure the PickerView to select the middle row when the orientation changes during scroll
        if isScrolling {
            let middleRow = Int(ceil(Float(numberOfRowsByDataSource) / 2.0))
            selectedNearbyToMiddleRow(middleRow)
        } else {
            let rowToSelect = currentSelectedRow != nil ? currentSelectedRow : Int(ceil(Float(numberOfRowsByDataSource) / 2.0))
            selectedNearbyToMiddleRow(rowToSelect)
        }
        
        if firstTimeOrientationChanged {
            firstTimeOrientationChanged = false
            return
        }
        
        if !isScrolling {
            return
        }
        
        orientationChanged = true
    }
    
    // MARK: - Actions
    
    /**
        Selects the nearby to middle row that matches with the provided index.
    
        - parameter row: A valid index provided by Data Source.
    */
    private func selectedNearbyToMiddleRow(row: Int) {
        currentSelectedRow = row
        tableView.reloadData()
        
        repeat {
            // This line adjust the contentInset to UIEdgeInsetZero because when the PickerView are inside of a UIViewController 
            // presented by a UINavigation controller, the tableView contentInset is affected.
            tableView.contentInset = UIEdgeInsetsZero
            
            let indexOfSelectedRow = visibleIndexOfSelectedRow()
            tableView.setContentOffset(CGPoint(x: 0.0, y: CGFloat(indexOfSelectedRow) * rowHeight), animated: false)
            delegate?.pickerView(self, didSelectRow: row)
        } while !(numberOfRowsByDataSource > 0 && tableView.numberOfRowsInSection(0) > 0)
    }
    
    /**
        Selects literally the row with index that the user tapped.
    
        - parameter row: The row index that the user tapped, i.e. the Data Source index times the `infinityRowsMultiplier`.
    */
    private func selectTappedRow(row: Int) {
        tableView.setContentOffset(CGPoint(x: 0.0, y: CGFloat(row) * rowHeight), animated: true)
        delegate?.pickerView(self, didSelectRow: row % numberOfRowsByDataSource)
    }
    
    /**
        Configure the first row selection: If some pre-selected row was set, we select it, else we select the nearby to middle at all.
    */
    private func configureFirstSelection() {
        let rowToSelect = currentSelectedRow != nil ? currentSelectedRow : Int(ceil(Float(numberOfRowsByDataSource) / 2.0))
        selectedNearbyToMiddleRow(rowToSelect)
    }
    
    private func turnPickerViewOn() {
        tableView.scrollEnabled = true
    }
    
    private func turnPickerViewOff() {
        tableView.scrollEnabled = false
    }
    
    /**
        This is an private helper that we use to reach the visible index of the current selected row. 
        Because of we multiply the rows several times to create an Infinite Scrolling experience, the index of a visible selected row may
        not be the same as the index provided on Data Source.
    
        - returns: The visible index of current selected row.
    */
    private func visibleIndexOfSelectedRow() -> Int {
        let middleMultiplier = scrollingStyle == .Infinite ? (infinityRowsMultiplier / 2) : infinityRowsMultiplier
        let middleIndex = numberOfRowsByDataSource * middleMultiplier
        let indexForSelectedRow: Int
    
        if let _ = currentSelectedRow where scrollingStyle == .Default && currentSelectedRow == 0 {
            indexForSelectedRow = 0
        } else if let _ = currentSelectedRow {
            indexForSelectedRow = middleIndex - (numberOfRowsByDataSource - currentSelectedRow)
        } else {
            let middleRow = Int(ceil(Float(numberOfRowsByDataSource) / 2.0))
            indexForSelectedRow = middleIndex - (numberOfRowsByDataSource - middleRow)
        }
        
        return indexForSelectedRow
    }
    
}

extension PickerView: UITableViewDataSource {
    
    // MARK: UITableViewDataSource
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsByDataSource * infinityRowsMultiplier
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let pickerViewCell = tableView.dequeueReusableCellWithIdentifier(pickerViewCellIdentifier, forIndexPath: indexPath) as! SimplePickerTableViewCell
        
        // As the first row have a different size to fit in the middle of the PickerView and rows below, the titleLabel position must be adjusted.
        if indexPath.row == 0 {
            let centerY = (frame.height / 2) - (rowHeight / 2)
            pickerViewCell.titleLabel.frame = CGRect(x: 0.0, y: centerY, width: frame.width, height: rowHeight)
        } else {
            pickerViewCell.titleLabel.frame = CGRect(x: 0.0, y: 0.0, width: frame.width, height: rowHeight)
        }
        
        pickerViewCell.selectionStyle = .None
        pickerViewCell.backgroundColor = pickerCellBackgroundColor ?? UIColor.whiteColor()
        pickerViewCell.contentView.addSubview(pickerViewCell.titleLabel)
        pickerViewCell.titleLabel.backgroundColor = UIColor.clearColor()
        pickerViewCell.titleLabel.text = dataSource?.pickerView(self, titleForRow: indexPath.row % numberOfRowsByDataSource)

        let indexOfSelectedRow = visibleIndexOfSelectedRow()
        
        if indexPath.row == indexOfSelectedRow {
            delegate?.styleForHighlightedLabel(pickerViewCell.titleLabel, inPickerView: self)
        } else {
            delegate?.styleForLabel(pickerViewCell.titleLabel, inPickerView: self)
        }
        
        return pickerViewCell
    }
    
}

extension PickerView: UITableViewDelegate {
    
    // MARK: UITableViewDelegate
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectTappedRow(indexPath.row)
    }
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let numberOfRowsInPickerView = dataSource!.numberOfRowsInPickerView(self) * infinityRowsMultiplier
        
        // When the scrolling reach the end on top/bottom we need to set the first/last row to appear in the center of PickerView, so that row must be bigger.
        if indexPath.row == 0 {
            return (frame.height / 2) + (rowHeight / 2)
        } else if numberOfRowsInPickerView > 0 && indexPath.row == numberOfRowsInPickerView - 1 {
            return (frame.height / 2) + (rowHeight / 2)
        }
        
        return rowHeight
    }
    
}

extension PickerView: UIScrollViewDelegate {
    
    // MARK: UIScrollViewDelegate
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        isScrolling = true
    }
    
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let partialRow = Float(targetContentOffset.memory.y / rowHeight) // Get the estimative of what row will be the selected when the scroll animation ends.
        var roundedRow = Int(lroundf(partialRow)) // Round the estimative to a row
        
        if roundedRow < 0 {
            roundedRow = 0
        } else {
            targetContentOffset.memory.y = CGFloat(roundedRow) * rowHeight // Set the targetContentOffset (where the scrolling position will be when the animation ends) to a rounded value.
        }
        
        // Update the currentSelectedRow and notify the delegate that we have a new selected row.
        currentSelectedRow = roundedRow % numberOfRowsByDataSource
        delegate?.pickerView(self, didSelectRow: roundedRow % dataSource!.numberOfRowsInPickerView(self))
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // When the orientation changes during the scroll, is required to reset the picker to select the nearby to middle row.
        if orientationChanged {
            selectedNearbyToMiddleRow(currentSelectedRow)
            orientationChanged = false
        }
        
        isScrolling = false
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        let partialRow = Float(scrollView.contentOffset.y / rowHeight)
        let roundedRow = Int(lroundf(partialRow))
        
        // Avoid to have two highlighted rows at the same time
        if let visibleRows = tableView.indexPathsForVisibleRows {
            for indexPath in visibleRows {
                if let cellToUnhighlight = tableView.cellForRowAtIndexPath(indexPath) as? SimplePickerTableViewCell {
                    delegate?.styleForLabel(cellToUnhighlight.titleLabel, inPickerView: self)
                }
            }
        }
        
        // Highlight the current selected cell during scroll
        if let cellToHighlight = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: roundedRow, inSection: 0)) as? SimplePickerTableViewCell {
            delegate?.styleForHighlightedLabel(cellToHighlight.titleLabel, inPickerView: self)
        }
    }
    
}