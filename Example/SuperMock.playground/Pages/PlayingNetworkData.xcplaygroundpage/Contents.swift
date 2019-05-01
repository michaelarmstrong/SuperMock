//: ### [<< Previous](@previous)
// If you cannot see this file correctly go on the menu Editor -> Show Render Markup.
// Build the project at least once before run the playground.
import Foundation
@testable import SuperMock
/*:
 # SuperMock: Playing network calls
 ### This section will show how to make supermock reply with mocks to your network calls
 ### We have a file of mocks, the same seen in the recording session, so if you have already seen it you can skip this section. The mocks tell to supermock what to reply to API calls if a url is not in the mocks the framework let it go through and hit the network. It is organised in GET, PUT, POST, DELETE categories and each category contains the related urls, each url contain an array of dictionary of "response" "data" key that represent response headers and response body. They hold the link of the files that contain the real data. The file need to be part of your resouces to be used in the play function.
 */
let bundle = Bundle.main

if let path = bundle.path(forResource: "Mocks", ofType: "plist") {
    let mocks = NSDictionary(contentsOf: URL(fileURLWithPath: path))?["mocks"] as? [String: Any]
    let getCalls = mocks?["GET"] as? [String: Any]
    let appleCalls = getCalls?["http://apple.com/uk"] as? [[String:String]]
    appleCalls?.count
}
/*:
 ### To obtain the mock from the call we just need to make the call to the network after the framework has begin mocking
 */
SuperMock.beginMocking(bundle)

var fileBundle = SuperMockResponseHelper.bundleForMocks
var mocks = SuperMockResponseHelper.sharedHelper.mocks
var GETs =  mocks["GET"] as? [String: Any]
let url = URL(string:"http://apple.com/uk")!
GETs?[url.absoluteString]

var completed = false
getTheUKApplePage() { (bytes, status, success) in
    bytes
    status
    success
    completed = true
}
while !completed {}
completed = false
/*:
 ### As you can notice the response size of our network call is 52815 and the response status 200. What happen if I make the same call a second time? Accordingly to our mock call the second call should return a response with status code 400 and same body.
 */
getTheUKApplePage() { (bytes, status, success) in
    bytes
    status
    success
    completed = true
}
while !completed {}
completed = false
/*:
 ### What happen if I make the same call a third time? Accordingly to our mock call the second call should return a response with status code 200 and changed body, the size of the data is 54961 bytes this time.
 */
getTheUKApplePage() { (bytes, status, success) in
    bytes
    status
    success
    completed = true
}
while !completed {}
/*:
 ### always remember to terminate the recording, it is good practice.
 */
SuperMock.endMocking()
/*:
 ### In case you are using a URLSession that is not the default one you need to register the protocols once the URLSession is created.
 */
let customSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "SuperMockBackgroundConfiguration")
let customURLSession = URLSession(configuration: customSessionConfiguration)

SuperMock.beginMocking(bundle, configuration: customSessionConfiguration, session: customURLSession)

fileBundle = SuperMockResponseHelper.bundleForMocks
/*:
 ### always remember to terminate the recording, it is good practice.
 */
SuperMock.endMocking()
/*:
 ### Everything from now on will behave normally and the calls will hit the network.
 */


