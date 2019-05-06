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
* Pure Swift 4.2
* Very flexible


## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.
Follow the Playground to learn how to use it.

Define any mocks for your application in a mocks plist file similar to the example included.

The plist file will contain a dictionary for each API call with an array of dictionaries with "data" for Response NSData and "response" for the HTTP Response Fields (plist file of http headers).

Enter 2 lines of code 
```
let appBundle = NSBundle(forClass: AppDelegate.self)
SuperMock.beginMocking(appBundle)
```

Your URL requests throughout your existing code base will begin to return Mocks!


### RECORD 
Record the Response and the headers using the recording functionality.

Enter 2 lines of code to start to record
```
let appBundle = NSBundle(forClass: AppDelegate.self)
SuperMock.beginRecording(appBundle, policy: .Override)
```
If the project bundle has a Mock.plist file, it will copy the file and fill the file with the new recorded urls. 
If you do not have a Mock.plist file in your project it will create one.
You can specify the mock.plist file when you begin to record
```
SuperMock.beginRecording(appBundle, mocksFile: "NewMock", policy: .Record)
```
It is recording the data in the Documents folder of the mobile application, for example in the simulator:
```
/Users/USERNAME/Library/Developer/CoreSimulator/Devices/142D41E4-6938-4E36-9B1F-61F5D4D5B801/data/Containers/Data/Application/376E490D-8F99-4A09-AEFD-A52B8FA6C76F/Documents
```

The log of the recording will help to find the right folder


## Installation

SuperMock is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
use_frameworks!
pod "SuperMock"
```

## Authors

Michael Armstrong, [@ArmstrongAtWork](http://twitter.com/ArmstrongAtWork), Daniele Forlani

## License

SuperMock is available under the MIT license. See the LICENSE file for more info.
