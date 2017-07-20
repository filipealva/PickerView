# PickerView

[![Version](https://img.shields.io/cocoapods/v/PickerView.svg?style=flat)](http://cocoapods.org/pods/PickerView)
[![License](https://img.shields.io/cocoapods/l/PickerView.svg?style=flat)](http://cocoapods.org/pods/PickerView)
[![Platform](https://img.shields.io/cocoapods/p/PickerView.svg?style=flat)](http://cocoapods.org/pods/PickerView)

`PickerView` is an easy to use and customize alternative to `UIPickerView` written in Swift. It was developed to provide a highly customizable experience, so you can implement your custom designed `UIPickerView`. 

<p align="center"><img src ="https://github.com/filipealva/PickerView/raw/master/Demo.gif" /></p>

## Requirements

It requires Xcode 8.0+ and Swift 3.0.

**NOTE:** When `PickerView` was first built it wasn't thought to support Objective-C projects, but the community demanded it and recently we've released the version `0.2.0` which supports Objective-C projects. After some tests we noticed some bugs when using from Objective-C, so we've this [issue](https://github.com/filipealva/PickerView/issues/11) open and we need some help to fix that, so if you are making some adjustments to run in your Objective-C project, please, contribute with us to fix these problems. Thanks.

Your project deployment target must be `iOS 8.0+`

## Installation

### CocoaPods

PickerView is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "PickerView"
```

### Manually

You can also install it manually just draging [PickerView](https://github.com/filipealva/PickerView/blob/master/Pod/Classes/PickerView.swift) file to your project. 

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

`PickerView` is very simple to use, you can use it with Interface Builder or through code, it works similar as `UIPickerView` you need to implement `PickerViewDataSource` and `PickerViewDelegate` protocols to provide the basic information and make it works.

You can customize the text appearance, the scrolling style (default or infinite scrolling) and the selection style (selection indicators and overlays with custom `UIView`'s or even an `UIImage` to highlight the selected row). 

### Interface Builder

Drag a `UIView` to your view controller (and put the constraints if you want).

<p align="center"><img src="http://s1.postimg.org/irrjykj33/Captura_de_Tela_2015_10_07_s_13_00_11.png" border="0" alt="Putting PickerView on Interface Builder" height="320px" width="337px"/></p>

Change the class to `PickerView` on the Identity Inspector **and make the** `@IBOutlet` **connection**.

<p align="center"><img src="http://s30.postimg.org/koz421nk1/Captura_de_Tela_2015_10_07_s_13_15_06.png" border="0" alt="Change the custom class." height="200px" width="214px"/></p>

### From Code

Create a new `PickerView`.

```swift
let examplePicker = PickerView()
examplePicker.translatesAutoresizingMaskIntoConstraints = false
```

Add to your view and put your custom constraints.

```swift
view.addSubview(examplePicker)
view.addConstraints([yourCustomConstraints])
```

### Set the `PickerViewDataSource` and `PickerViewDelegate`

Don't forget to set the datasource and delegate of your `PickerView`:

```swift
// ...
// The `examplePicker` below is the same that you created through code or connected via @IBOutlet
examplePicker.dataSource = self
examplePicker.delegate = self
// ...
```

### Implement `PickerViewDataSource`

The `PickerViewDataSource` protocol consists in two required methods:

```swift
@objc public protocol PickerViewDataSource: class {
    func pickerViewNumberOfRows(_ pickerView: PickerView) -> Int
    func pickerView(_ pickerView: PickerView, titleForRow row: Int, index: Int) -> String
}
```

You need to return the `pickerViewNumberOfRows` as we see below:

```swift
func pickerViewNumberOfRows(_ pickerView: PickerView) -> Int {
    return itemsThatYouWantToPresent.count 
}
```

And the title for each row:

```swift
func pickerView(_ pickerView: PickerView, titleForRow row: Int, index: Int) -> String {
    let item = itemsThatYouWantToPresent[index] // NOTE: Use `index` instead of `row` to retrieve your data correctly
    return item.text
}
```

Done. Now you'll need to implement one more protocol and then we are all set.

### Implement `PickerViewDelegate`

The `PickerViewDelegate` consists in five methods:

```swift
@objc public protocol PickerViewDelegate: class {
    func pickerViewHeightForRows(_ pickerView: PickerView) -> CGFloat
    optional func pickerView(_ pickerView: PickerView, didSelectRow row: Int, index: Int)
    optional func pickerView(_ pickerView: PickerView, didTapRow row: Int, index: Int)
    optional func pickerView(_ pickerView: PickerView, styleForLabel label: UILabel, highlighted: Bool)
    optional func pickerView(_ pickerView: PickerView, viewForRow row: Int, index: Int, highlighted: Bool, reusingView view: UIView?) -> UIView?
}
```

Firstly you must provide the `pickerViewHeightForRows(_:)`:

```swift
func pickerViewHeightForRows(_ pickerView: PickerView) -> CGFloat {
    return 50.0 // In this example I'm returning arbitrary 50.0pt but you should return the row height you want.
}
```

Then is the method where you can do something with the row selected in `PickerView`:

```swift
func pickerView(_ pickerView: PickerView, didSelectRow row: Int) {
    let selectedItem = itemsThatYouWantToPresent[row] 
    print("The selected item is \(selectedItem.name)") 
}
```

`PickerView` enable the user to tap a visible row to select it. We've a delegate method to track this tap behavior, so `pickerView(_: PickerView, didTapRow row: Int, index: Int)` is called only when the user selects a row by tapping it:

```swift
func pickerView(_ pickerView: PickerView, didTapRow row: Int, index: Int) {
    print("The row \(row) was tapped by the user") 
}
```

The following method allows you to customize the label that will present your items in `PickerView`. Use the flag `highlighted' to provide a differrent style when the item is selected:

```swift
func pickerView(_ pickerView: PickerView, styleForLabel label: UILabel, highlighted: Bool) {
    label.textAlignment = .Center
    
    if highlighted { 
        label.font = UIFont.systemFontOfSize(25.0)
        label.textColor = view.tintColor
    } else {
        label.font = UIFont.systemFontOfSize(15.0)
        label.textColor = .lightGrayColor()
    }
}
```

If you want to provide a totally customized view instead of presenting just a row with a text label inside

```swift
func pickerView(_ pickerView: PickerView, viewForRow row: Int, index: Int, highlighted: Bool, reusingView view: UIView?) -> UIView? {
    var customView = view
    
    // Verify if there is a view to reuse, if not, init your view. 
    if customView == nil {
        // Init your view
        customView = MyCustomView()
    }
    
    // **IMPORTANT**: As you are providing a totally custom view, PickerView doesn't know where to bind the data provided on PickerViewDataSource, so you will need to bind the data in this method. 
    customView.yourCustomTextLabel.text = itemsThatYouWantToPresent[index].text
    
    // Don't forget to make your style customizations for highlighted state 
    let alphaBasedOnHighlighted: CGFloat = highlighted ? 1.0 : 0.5
    customView.yourCustomTextLabel.alpha = alphaBasedOnHighlighted
    
    return customView
}
```

#### Label or Custom View?

Even if `func pickerView(_ pickerView: PickerView, styleForLabel label: UILabel, highlighted: Bool)` and `func pickerView(_ pickerView: PickerView, viewForRow row: Int, index: Int, highlited: Bool, reusingView view: UIView?)` are optional methods in `PickerViewDelegate` you must implement at least one of them. If you want to present your data using only a label (which you can customize too), implement the first one, but if you want to present your data in a totally customized view, you should implement the second one. 

**NOTE:** If you implement the two methods mentioned above, `PickerView` will always present your data using the custom view you provided. 

Cool! You are ready to build and run your application with `PickerView`, it ill works with the default configurations and the text appearance you provided in `PickerViewDelegate` on the next section we will cover the scrolling and selection style customizations.

## Custom Appearance

As you can customize the text appearance through `PickerViewDelegate`, you have two more options to customize your `PickerView`: scrolling style and selection style.

### Scrolling Style 

Is defined by the `scrollingStyle` property of `PickerView` that is of type `ScrollingStyle` a nested `enum` that has two member values: `.Default` and `.Infinite`. It is explicit and you might already know what it does, but let me explain better:

**.Default**: The default scrolling experience, the user can scroll through your `PickerView` item's but he will reach the bottom or the top of your picker when it doesn't have more items to show.

**.Infinite**: With this scrolling style the user will loop through the items of your `PickerView` and never reach the end, it provides an infinite scrolling experience.

### Selection Style

Is defined by the `selectionStyle` property of `PickerView` that is of type `SelectionStyle` a nested `enum` that has four member values: `.None`, `.DefaultIndicator`, `.Overlay` and `.Image`. For your better understanding, follow the explanation below:

**.None**: Don't uses any aditional view to highlight the selection, only the highlighted label style customization provided by delegate.

**.DefaultIndicator**: Provides a simple selection indicator on the bottom of the highlighted row with full width and 2pt of height. The default color is its superview `tintColor` but you have free access to customize the DefaultIndicator through the `defaultSelectionIndicator` property.

**.Overlay**: Provide a full width and height (the height you provided on delegate) view that overlay the highlighted row. The default color is its superview `tintColor` and the alpha is set to 0.25, but you have free access to customize it through the `selectionOverlay` property. 

*Tip: You can set the alpha to 1.0 and background color to .clearColor() and add your custom selection view as a `selectionOverlay` subview to make it looks as you want (don't forget to properly add the constraints related to `selectionOverlay` to keep your experience with any screen size).*

**.Image**: Provide a full width and height image view selection indicator (the height you provided on delegate) without any image. You **must** have a selection indicator as an image and set it to the image view through the `selectionImageView` property.

## Who's Using It? 

See what projects are using `PickerView` on [our wiki page](https://github.com/filipealva/PickerView/wiki).

## Contribute

Feel free to submit your pull request, suggest any update, report a bug or create a feature request. 

Before you start contributing, please take a look on our [contributing guide](https://github.com/filipealva/PickerView/blob/master/CONTRIBUTING.md).

Just want to say `hello`? -> ofilipealvarenga at gmail.com

## Contributors

Author: [@filipealva](https://twitter.com/filipealva) 

See the people who helps to improve this project: [Contributors](https://github.com/filipealva/PickerView/graphs/contributors) ♥

**Special thanks to**: [@bguidolim](https://twitter.com/bguidolim) and [@jairobjunior](https://github.com/jairobjunior).

## Starring is caring 🌟

If you liked the project and want it to continue, please star it. It is a way for me to know the impact of the project. Thank you <3 

## License

PickerView is available under the MIT license. See the LICENSE file for more info.
