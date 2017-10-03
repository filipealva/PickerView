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

@objc public protocol PickerViewDataSource: class {
    func pickerViewNumberOfRows(_ pickerView: PickerView) -> Int
    func pickerView(_ pickerView: PickerView, titleForRow row: Int, index: Int) -> String
}

@objc public protocol PickerViewDelegate: class {
    func pickerViewHeightForRows(_ pickerView: PickerView) -> CGFloat
    @objc optional func pickerView(_ pickerView: PickerView, didSelectRow row: Int, index: Int)
    @objc optional func pickerView(_ pickerView: PickerView, didTapRow row: Int, index: Int)
    @objc optional func pickerView(_ pickerView: PickerView, styleForLabel label: UILabel, highlighted: Bool)
    @objc optional func pickerView(_ pickerView: PickerView, viewForRow row: Int, index: Int, highlighted: Bool, reusingView view: UIView?) -> UIView?
}

open class PickerView: UIView {
    
    // MARK: Nested Types
    
    fileprivate class SimplePickerTableViewCell: UITableViewCell {
        lazy var titleLabel: UILabel = {
            let titleLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: self.contentView.frame.width, height: self.contentView.frame.height))
            titleLabel.textAlignment = .center
            
            return titleLabel
        }()
        
        var customView: UIView?
    }
    
    /**
        ScrollingStyle Enum.
    
        - parameter Default: Show only the number of rows informed in data source.
    
        - parameter Infinite: Loop through the data source offering a infinite scrolling experience to the user.
    */
    
    @objc public enum ScrollingStyle: Int {
        case `default`, infinite
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
    
    @objc public enum SelectionStyle: Int {
        case none, defaultIndicator, overlay, image
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
    
    fileprivate var selectionOverlayH: NSLayoutConstraint!
    fileprivate var selectionImageH: NSLayoutConstraint!
    fileprivate var selectionIndicatorB: NSLayoutConstraint!
    fileprivate var pickerCellBackgroundColor: UIColor?
    
    var numberOfRowsByDataSource: Int {
        get {
            return dataSource?.pickerViewNumberOfRows(self) ?? 0
        }
    }
    
    var rowHeight: CGFloat {
        get {
            return delegate?.pickerViewHeightForRows(self) ?? 0
        }
    }
    
    override open var backgroundColor: UIColor? {
        didSet {
            self.tableView.backgroundColor = self.backgroundColor
            self.pickerCellBackgroundColor = self.backgroundColor
        }
    }
    
    fileprivate let pickerViewCellIdentifier = "pickerViewCell"
    
    open weak var dataSource: PickerViewDataSource?
    open weak var delegate: PickerViewDelegate?
    
    open lazy var defaultSelectionIndicator: UIView = {
        let selectionIndicator = UIView()
        selectionIndicator.backgroundColor = self.tintColor
        selectionIndicator.alpha = 0.0
        
        return selectionIndicator
    }()
    
    open lazy var selectionOverlay: UIView = {
        let selectionOverlay = UIView()
        selectionOverlay.backgroundColor = self.tintColor
        selectionOverlay.alpha = 0.0
        
        return selectionOverlay
    }()
    
    open lazy var selectionImageView: UIImageView = {
        let selectionImageView = UIImageView()
        selectionImageView.alpha = 0.0
        
        return selectionImageView
    }()
    
    public lazy var tableView: UITableView = {
        let tableView = UITableView()
        
        return tableView
    }()
    
    fileprivate var infinityRowsMultiplier: Int = 1
    fileprivate var hasTouchedPickerViewYet = false
    open var currentSelectedRow: Int!
    open var currentSelectedIndex: Int {
        get {
            return indexForRow(currentSelectedRow)
        }
    }
    
    fileprivate var firstTimeOrientationChanged = true
    fileprivate var orientationChanged = false
    fileprivate var isScrolling = false
    fileprivate var setupHasBeenDone = false
    
    open var scrollingStyle = ScrollingStyle.default {
        didSet {
            switch scrollingStyle {
            case .default:
                infinityRowsMultiplier = 1
            case .infinite:
                infinityRowsMultiplier = generateInfinityRowsMultiplier()
            }
        }
    }
    
    open var selectionStyle = SelectionStyle.none {
        didSet {
            switch selectionStyle {
            case .defaultIndicator:
                defaultSelectionIndicator.alpha = 1.0
                selectionOverlay.alpha = 0.0
                selectionImageView.alpha = 0.0
            case .overlay:
                selectionOverlay.alpha = 0.25
                defaultSelectionIndicator.alpha = 0.0
                selectionImageView.alpha = 0.0
            case .image:
                selectionImageView.alpha = 1.0
                selectionOverlay.alpha = 0.0
                defaultSelectionIndicator.alpha = 0.0
            case .none:
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
    
    fileprivate func setup() {
        infinityRowsMultiplier = generateInfinityRowsMultiplier()
        
        // Setup subviews constraints and apperance
        translatesAutoresizingMaskIntoConstraints = false
        setupTableView()
        setupSelectionOverlay()
        setupSelectionImageView()
        setupDefaultSelectionIndicator()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
        
        // This needs to be done after a delay - I am guessing it basically needs to be called once 
        // the view is already displaying
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            // Some UI Adjustments we need to do after setting UITableView data source & delegate.
            self.configureFirstSelection()
            self.adjustSelectionOverlayHeightConstraint()
        }
    }
    
    fileprivate func setupTableView() {
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.separatorColor = .none
        tableView.allowsSelection = true
        tableView.allowsMultipleSelection = false
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.scrollsToTop = false
        tableView.register(SimplePickerTableViewCell.classForCoder(), forCellReuseIdentifier: self.pickerViewCellIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tableView)
        
        let tableViewH = NSLayoutConstraint(item: tableView, attribute: .height, relatedBy: .equal, toItem: self,
                                                attribute: .height, multiplier: 1, constant: 0)
        addConstraint(tableViewH)
        
        let tableViewW = NSLayoutConstraint(item: tableView, attribute: .width, relatedBy: .equal, toItem: self,
                                                attribute: .width, multiplier: 1, constant: 0)
        addConstraint(tableViewW)
        
        let tableViewL = NSLayoutConstraint(item: tableView, attribute: .leading, relatedBy: .equal, toItem: self,
                                                attribute: .leading, multiplier: 1, constant: 0)
        addConstraint(tableViewL)
        
        let tableViewTop = NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal, toItem: self,
                                                attribute: .top, multiplier: 1, constant: 0)
        addConstraint(tableViewTop)
        
        let tableViewBottom = NSLayoutConstraint(item: tableView, attribute: .bottom, relatedBy: .equal, toItem: self,
                                                    attribute: .bottom, multiplier: 1, constant: 0)
        addConstraint(tableViewBottom)
        
        let tableViewT = NSLayoutConstraint(item: tableView, attribute: .trailing, relatedBy: .equal, toItem: self,
                                                attribute: .trailing, multiplier: 1, constant: 0)
        addConstraint(tableViewT)
    }
    
    fileprivate func setupSelectionOverlay() {
        selectionOverlay.isUserInteractionEnabled = false
        selectionOverlay.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(selectionOverlay)
        
        selectionOverlayH = NSLayoutConstraint(item: selectionOverlay, attribute: .height, relatedBy: .equal, toItem: nil,
                                                attribute: .notAnAttribute, multiplier: 1, constant: rowHeight)
        self.addConstraint(selectionOverlayH)
        
        let selectionOverlayW = NSLayoutConstraint(item: selectionOverlay, attribute: .width, relatedBy: .equal, toItem: self,
                                                    attribute: .width, multiplier: 1, constant: 0)
        addConstraint(selectionOverlayW)
        
        let selectionOverlayL = NSLayoutConstraint(item: selectionOverlay, attribute: .leading, relatedBy: .equal, toItem: self,
                                                    attribute: .leading, multiplier: 1, constant: 0)
        addConstraint(selectionOverlayL)
        
        let selectionOverlayT = NSLayoutConstraint(item: selectionOverlay, attribute: .trailing, relatedBy: .equal, toItem: self,
                                                    attribute: .trailing, multiplier: 1, constant: 0)
        addConstraint(selectionOverlayT)
        
        let selectionOverlayY = NSLayoutConstraint(item: selectionOverlay, attribute: .centerY, relatedBy: .equal, toItem: self,
                                                    attribute: .centerY, multiplier: 1, constant: 0)
        addConstraint(selectionOverlayY)
    }
    
    fileprivate func setupSelectionImageView() {
        selectionImageView.isUserInteractionEnabled = false
        selectionImageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(selectionImageView)
        
        selectionImageH = NSLayoutConstraint(item: selectionImageView, attribute: .height, relatedBy: .equal, toItem: nil,
                                                attribute: .notAnAttribute, multiplier: 1, constant: rowHeight)
        self.addConstraint(selectionImageH)
        
        let selectionImageW = NSLayoutConstraint(item: selectionImageView, attribute: .width, relatedBy: .equal, toItem: self,
                                                    attribute: .width, multiplier: 1, constant: 0)
        addConstraint(selectionImageW)
        
        let selectionImageL = NSLayoutConstraint(item: selectionImageView, attribute: .leading, relatedBy: .equal, toItem: self,
                                                    attribute: .leading, multiplier: 1, constant: 0)
        addConstraint(selectionImageL)
        
        let selectionImageT = NSLayoutConstraint(item: selectionImageView, attribute: .trailing, relatedBy: .equal, toItem: self,
                                                    attribute: .trailing, multiplier: 1, constant: 0)
        addConstraint(selectionImageT)
        
        let selectionImageY = NSLayoutConstraint(item: selectionImageView, attribute: .centerY, relatedBy: .equal, toItem: self,
                                                    attribute: .centerY, multiplier: 1, constant: 0)
        addConstraint(selectionImageY)
    }
    
    fileprivate func setupDefaultSelectionIndicator() {
        defaultSelectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(defaultSelectionIndicator)
        
        let selectionIndicatorH = NSLayoutConstraint(item: defaultSelectionIndicator, attribute: .height, relatedBy: .equal, toItem: nil,
                                                        attribute: .notAnAttribute, multiplier: 1, constant: 2.0)
        addConstraint(selectionIndicatorH)
        
        let selectionIndicatorW = NSLayoutConstraint(item: defaultSelectionIndicator, attribute: .width, relatedBy: .equal,
                                                        toItem: self, attribute: .width, multiplier: 1, constant: 0)
        addConstraint(selectionIndicatorW)
        
        let selectionIndicatorL = NSLayoutConstraint(item: defaultSelectionIndicator, attribute: .leading, relatedBy: .equal,
                                                        toItem: self, attribute: .leading, multiplier: 1, constant: 0)
        addConstraint(selectionIndicatorL)
        
        selectionIndicatorB = NSLayoutConstraint(item: defaultSelectionIndicator, attribute: .bottom, relatedBy: .equal,
                                                    toItem: self, attribute: .centerY, multiplier: 1, constant: (rowHeight / 2))
        addConstraint(selectionIndicatorB)
        
        let selectionIndicatorT = NSLayoutConstraint(item: defaultSelectionIndicator, attribute: .trailing, relatedBy: .equal,
                                                        toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
        addConstraint(selectionIndicatorT)
    }
    
    // MARK: Infinite Scrolling Helpers
    
    fileprivate func generateInfinityRowsMultiplier() -> Int {
        if scrollingStyle == .default {
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
    
    open override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        if let _ = newWindow {
            NotificationCenter.default.addObserver(self, selector: #selector(PickerView.adjustCurrentSelectedAfterOrientationChanges),
                                                            name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        } else {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        if !setupHasBeenDone {
            setup()
            setupHasBeenDone = true
        }
    }
    
    fileprivate func adjustSelectionOverlayHeightConstraint() {
        if selectionOverlayH.constant != rowHeight || selectionImageH.constant != rowHeight || selectionIndicatorB.constant != (rowHeight / 2) {
            selectionOverlayH.constant = rowHeight
            selectionImageH.constant = rowHeight
            selectionIndicatorB.constant = -(rowHeight / 2)
            layoutIfNeeded()
        }
    }
    
    @objc func adjustCurrentSelectedAfterOrientationChanges() {
        setNeedsLayout()
        layoutIfNeeded()
        
        // Configure the PickerView to select the middle row when the orientation changes during scroll
        if isScrolling {
            let middleRow = Int(ceil(Float(numberOfRowsByDataSource) / 2.0))
            selectedNearbyToMiddleRow(middleRow)
        } else {
            let rowToSelect = currentSelectedRow != nil ? currentSelectedRow : Int(ceil(Float(numberOfRowsByDataSource) / 2.0))
            selectedNearbyToMiddleRow(rowToSelect!)
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
    
    fileprivate func indexForRow(_ row: Int) -> Int {
        return row % (numberOfRowsByDataSource > 0 ? numberOfRowsByDataSource : 1)
    }
    
    // MARK: - Actions
    
    /**
        Selects the nearby to middle row that matches with the provided index.
    
        - parameter row: A valid index provided by Data Source.
    */
    fileprivate func selectedNearbyToMiddleRow(_ row: Int) {
        currentSelectedRow = row
        tableView.reloadData()
        
        repeat {
            // This line adjust the contentInset to UIEdgeInsetZero because when the PickerView are inside of a UIViewController 
            // presented by a UINavigation controller, the tableView contentInset is affected.
            tableView.contentInset = UIEdgeInsets.zero
            
            let indexOfSelectedRow = visibleIndexOfSelectedRow()
            tableView.setContentOffset(CGPoint(x: 0.0, y: CGFloat(indexOfSelectedRow) * rowHeight), animated: false)
            
            delegate?.pickerView?(self, didSelectRow: currentSelectedRow, index: currentSelectedIndex)
            
        } while !(numberOfRowsByDataSource > 0 && tableView.numberOfRows(inSection: 0) > 0)
    }
    
    /**
        Selects literally the row with index that the user tapped.
    
        - parameter row: The row index that the user tapped, i.e. the Data Source index times the `infinityRowsMultiplier`.
    */
    fileprivate func selectTappedRow(_ row: Int) {
        delegate?.pickerView?(self, didTapRow: row, index: indexForRow(row))
        selectRow(row, animated: true)
    }
    
    /**
        Configure the first row selection: If some pre-selected row was set, we select it, else we select the nearby to middle at all.
    */
    fileprivate func configureFirstSelection() {
        let rowToSelect = currentSelectedRow != nil ? currentSelectedRow : Int(ceil(Float(numberOfRowsByDataSource) / 2.0))
        selectedNearbyToMiddleRow(rowToSelect!)
    }
    
    fileprivate func turnPickerViewOn() {
        tableView.isScrollEnabled = true
    }
    
    fileprivate func turnPickerViewOff() {
        tableView.isScrollEnabled = false
    }
    
    /**
        This is an private helper that we use to reach the visible index of the current selected row. 
        Because of we multiply the rows several times to create an Infinite Scrolling experience, the index of a visible selected row may
        not be the same as the index provided on Data Source.
    
        - returns: The visible index of current selected row.
    */
    fileprivate func visibleIndexOfSelectedRow() -> Int {
        let middleMultiplier = scrollingStyle == .infinite ? (infinityRowsMultiplier / 2) : infinityRowsMultiplier
        let middleIndex = numberOfRowsByDataSource * middleMultiplier
        let indexForSelectedRow: Int
    
        if let _ = currentSelectedRow , scrollingStyle == .default && currentSelectedRow == 0 {
            indexForSelectedRow = 0
        } else if let _ = currentSelectedRow {
            indexForSelectedRow = middleIndex - (numberOfRowsByDataSource - currentSelectedRow)
        } else {
            let middleRow = Int(ceil(Float(numberOfRowsByDataSource) / 2.0))
            indexForSelectedRow = middleIndex - (numberOfRowsByDataSource - middleRow)
        }
        
        return indexForSelectedRow
    }
    
    open func selectRow(_ row : Int, animated: Bool) {
        
        var finalRow = row;
        
        if (scrollingStyle == .infinite && row < numberOfRowsByDataSource) {
            let selectedRow = currentSelectedRow ?? Int(ceil(Float(numberOfRowsByDataSource) / 2.0))
            let diff = (row % numberOfRowsByDataSource) - (selectedRow % numberOfRowsByDataSource)
            finalRow = selectedRow + diff
        }
        
        currentSelectedRow = finalRow
        
        delegate?.pickerView?(self, didSelectRow: currentSelectedRow, index: currentSelectedIndex)
        
        tableView.setContentOffset(CGPoint(x: 0.0, y: CGFloat(finalRow) * rowHeight), animated: animated)
    }
    
    open func reloadPickerView() {
        tableView.reloadData()
    }
    
}

extension PickerView: UITableViewDataSource {
    
    // MARK: UITableViewDataSource
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsByDataSource * infinityRowsMultiplier
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let indexOfSelectedRow = visibleIndexOfSelectedRow()
        
        let pickerViewCell = tableView.dequeueReusableCell(withIdentifier: pickerViewCellIdentifier, for: indexPath) as! SimplePickerTableViewCell
        
        let view = delegate?.pickerView?(self, viewForRow: (indexPath as NSIndexPath).row, index: indexForRow((indexPath as NSIndexPath).row), highlighted: (indexPath as NSIndexPath).row == indexOfSelectedRow, reusingView: pickerViewCell.customView)
        
        pickerViewCell.selectionStyle = .none
        pickerViewCell.backgroundColor = pickerCellBackgroundColor ?? UIColor.white
        
        if (view != nil) {
            var frame = view!.frame
            frame.origin.y = (indexPath as NSIndexPath).row == 0 ? (self.frame.height / 2) - (rowHeight / 2) : 0.0
            view!.frame = frame
            pickerViewCell.customView = view
            pickerViewCell.contentView.addSubview(pickerViewCell.customView!)
            
        } else {
            // As the first row have a different size to fit in the middle of the PickerView and rows below, the titleLabel position must be adjusted.
            let centerY = (indexPath as NSIndexPath).row == 0 ? (self.frame.height / 2) - (rowHeight / 2) : 0.0
            
            pickerViewCell.titleLabel.frame = CGRect(x: 0.0, y: centerY, width: frame.width, height: rowHeight)
            
            pickerViewCell.contentView.addSubview(pickerViewCell.titleLabel)
            pickerViewCell.titleLabel.backgroundColor = UIColor.clear
            pickerViewCell.titleLabel.text = dataSource?.pickerView(self, titleForRow: (indexPath as NSIndexPath).row, index: indexForRow((indexPath as NSIndexPath).row))
            
            delegate?.pickerView?(self, styleForLabel: pickerViewCell.titleLabel, highlighted: (indexPath as NSIndexPath).row == indexOfSelectedRow)
        }
        
        return pickerViewCell
    }
    
}

extension PickerView: UITableViewDelegate {
    
    // MARK: UITableViewDelegate
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectTappedRow((indexPath as NSIndexPath).row)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let numberOfRowsInPickerView = dataSource!.pickerViewNumberOfRows(self) * infinityRowsMultiplier
        
        // When the scrolling reach the end on top/bottom we need to set the first/last row to appear in the center of PickerView, so that row must be bigger.
        if (indexPath as NSIndexPath).row == 0 {
            return (frame.height / 2) + (rowHeight / 2)
        } else if numberOfRowsInPickerView > 0 && (indexPath as NSIndexPath).row == numberOfRowsInPickerView - 1 {
            return (frame.height / 2) + (rowHeight / 2)
        }

        return rowHeight
    }
    
}

extension PickerView: UIScrollViewDelegate {
    
    // MARK: UIScrollViewDelegate
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling = true
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let partialRow = Float(targetContentOffset.pointee.y / rowHeight) // Get the estimative of what row will be the selected when the scroll animation ends.
        var roundedRow = Int(lroundf(partialRow)) // Round the estimative to a row
        
        if roundedRow < 0 {
            roundedRow = 0
        } else {
            targetContentOffset.pointee.y = CGFloat(roundedRow) * rowHeight // Set the targetContentOffset (where the scrolling position will be when the animation ends) to a rounded value.
        }
        
        // Update the currentSelectedRow and notify the delegate that we have a new selected row.
        currentSelectedRow = roundedRow
        
        delegate?.pickerView?(self, didSelectRow: currentSelectedRow, index: currentSelectedIndex)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // When the orientation changes during the scroll, is required to reset the picker to select the nearby to middle row.
        if orientationChanged {
            selectedNearbyToMiddleRow(currentSelectedRow)
            orientationChanged = false
        }
        
        isScrolling = false
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let partialRow = Float(scrollView.contentOffset.y / rowHeight)
        let roundedRow = Int(lroundf(partialRow))
        
        // Avoid to have two highlighted rows at the same time
        if let visibleRows = tableView.indexPathsForVisibleRows {
            for indexPath in visibleRows {
                if let cellToUnhighlight = tableView.cellForRow(at: indexPath) as? SimplePickerTableViewCell , (indexPath as NSIndexPath).row != roundedRow {
                    let _ = delegate?.pickerView?(self, viewForRow: (indexPath as NSIndexPath).row, index: indexForRow((indexPath as NSIndexPath).row), highlighted: false, reusingView: cellToUnhighlight.customView)
                    delegate?.pickerView?(self, styleForLabel: cellToUnhighlight.titleLabel, highlighted: false)
                }
            }
        }
        
        // Highlight the current selected cell during scroll
        if let cellToHighlight = tableView.cellForRow(at: IndexPath(row: roundedRow, section: 0)) as? SimplePickerTableViewCell {
            let _ = delegate?.pickerView?(self, viewForRow: roundedRow, index: indexForRow(roundedRow), highlighted: true, reusingView: cellToHighlight.customView)
            let _ = delegate?.pickerView?(self, styleForLabel: cellToHighlight.titleLabel, highlighted: true)
        }
    }
    
}
