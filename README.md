# PickerView

[![Version](https://img.shields.io/cocoapods/v/PickerView.svg?style=flat)](http://cocoapods.org/pods/PickerView)
[![License](https://img.shields.io/cocoapods/l/PickerView.svg?style=flat)](http://cocoapods.org/pods/PickerView)
[![Platform](https://img.shields.io/cocoapods/p/PickerView.svg?style=flat)](http://cocoapods.org/pods/PickerView)

`PickerView` is an easy to use and customize alternative to `UIPickerView` written in Swift. It was developed to provide a highly customizable experience, so you can implement your custom designed `UIPickerView`. 

<p align="center"><img src ="https://github.com/filipealva/PickerView/raw/master/Demo.gif" /></p>

## Requirements

It requires Xcode 7.0+ and Swift 2.0.

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
public protocol PickerViewDataSource: class {
    func numberOfRowsInPickerView(pickerView: PickerView) -> Int
    func pickerView(pickerView: PickerView, titleForRow row:Int) -> String
}
```

You need to return the `numberOfRowsInPickerView` as we see below:

```swift
func numberOfRowsInPickerView(pickerView: PickerView) -> Int {
    return itemsThatYouWantToPresent.count 
}
```

And the title for each row:

```swift
func pickerView(pickerView: PickerView, titleForRow row: Int) -> String {
    let item = itemsThatYouWantToPresent[row] 
    return item.name 
}
```

Done. Now you'll need to implement one more protocol and then we are all set.

### Implement `PickerViewDelegate`

The `PickerViewDelegate` consists in four required methods:

```swift
public protocol PickerViewDelegate: class {
    func pickerView(pickerView: PickerView, didSelectRow row: Int)
    func heightForRowInPickerView(pickerView: PickerView) -> CGFloat
    func styleForLabel(label: UILabel, inPickerView pickerView: PickerView)
    func styleForHighlightedLabel(label: UILabel, inPickerView pickerView: PickerView)
}
```

The first method is where you can do something with the row selected in `PickerView`:

```swift
func pickerView(pickerView: PickerView, didSelectRow row: Int) {
    let selectedItem = itemsThatYouWantToPresent[row] 
    print("The selected item is \(selectedItem.name)") 
}
```

Then you must provide the `heightForRowInPickerView(_:)`:

```swift
func heightForRowInPickerView(pickerView: PickerView) -> CGFloat {
    return 50.0 // In this example I'm returning arbitrary 50.0pt but you can return the row height you want.
}
```

The following method allows you to customize the label that will present your items in `PickerView`:

```swift
func styleForLabel(label: UILabel, inPickerView pickerView: PickerView) {
    label.textAlignment = .Center
    label.font = UIFont.systemFontOfSize(15.0)
    label.textColor = .lightGrayColor()
}
```

And this method allows you to customize the label of highlighted row in `PickerView`:

```swift
func styleForLabel(label: UILabel, inPickerView pickerView: PickerView) {
    label.textAlignment = .Center
    label.font = UIFont.systemFontOfSize(25.0) // Change the size of font
    label.textColor = view.tintColor // Change the text color
}
```

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

## License

PickerView is available under the MIT license. See the LICENSE file for more info.
