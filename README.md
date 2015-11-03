# SuperMock

[![CI Status](http://img.shields.io/travis/michaelarmstrong/SuperMock.svg?style=flat)](https://travis-ci.org/Michael Armstrong/SuperMock)
[![Version](https://img.shields.io/cocoapods/v/SuperMock.svg?style=flat)](http://cocoapods.org/pods/SuperMock)
[![License](https://img.shields.io/cocoapods/l/SuperMock.svg?style=flat)](http://cocoapods.org/pods/SuperMock)
[![Platform](https://img.shields.io/cocoapods/p/SuperMock.svg?style=flat)](http://cocoapods.org/pods/SuperMock)

A very simple yet powerful UI and Unit testing mock framework for API calls. It lives in your app and is completely offline.

* Mock once, use forever.
* Works offline
* No Server
* No Proxies
* Pure Swift / Objective-C
* Very flexible

[Reasoning, Motivation and More info about the project](http://mike.kz/general/mocking-data-for-ui-testing-in-xcode-7/)


## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

Define any mocks for your application in
```
Mocks.plist
```
[![Mocks plist example](http://mike.kz/wp-content/uploads/2015/11/Screen-Shot-2015-11-02-at-22.32.51.png)

Enter 2 lines of code into your AppDelegate (conditionally for your test target if required)
```
let appBundle = NSBundle(forClass: AppDelegate.self)
SuperMock.beginMocking(appBundle)
```
[![AppDelegate example](http://mike.kz/wp-content/uploads/2015/11/Screen-Shot-2015-11-02-at-22.34.02.png)

Your URL requests throughout your existing code base will begin to return Mocks!



## Requirements

## Installation

SuperMock is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
use_frameworks!
pod "SuperMock"
```

## Author

Michael Armstrong, [@ArmstrongAtWork](http://twitter.com/ArmstrongAtWork)

## License

SuperMock is available under the MIT license. See the LICENSE file for more info.
