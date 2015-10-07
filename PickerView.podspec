#
# Be sure to run `pod lib lint PickerView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = "PickerView"
s.version          = "0.1.0"
s.summary          = "A customizable alternative to UIPickerView."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!
s.description      = <<-DESC
PickerView is an easy to use and customize alternative to UIPickerView written in Swift. It was developed to provide a highly customizable experience, so you can implement your custom designed UIPickerView.
DESC

s.homepage         = "https://github.com/filipealva/PickerView"
# s.screenshots     = "http://s13.postimg.org/kaq8txo87/Captura_de_Tela_2015_10_05_s_11_01_06.png", "http://s13.postimg.org/i4vxzfkrr/Captura_de_Tela_2015_10_05_s_11_00_42.png", "http://s13.postimg.org/ou2hfg63r/Captura_de_Tela_2015_10_05_s_11_00_54.png"
s.license          = 'MIT'
s.author           = { "Filipe Alvarenga" => "ofilipealvarenga@gmail.com" }
s.source           = { :git => "https://github.com/filipealva/PickerView.git", :tag => s.version.to_s }
# s.social_media_url = 'https://twitter.com/filipealva'

s.platform     = :ios, '8.0'
s.requires_arc = true

s.source_files = 'Pod/Classes/**/*'
s.resource_bundles = {
'PickerView' => ['Pod/Assets/*.png']
}

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
