//: ### [<< Previous Page](@previous)
// If you cannot see this file correctly go on the menu Editor -> Show Render Markup.
// Build the project at least once before run the playground.
import Foundation
@testable import SuperMock
/*:

 # SuperMock: Recording network calls
 ### This section will show how to record a network call
 ### Let's start with a simple network call to apple uk and record the data coming from there. The recording will record a 200 response as well as a 400 or 500. Let's start with a working internet connection. If you specify a file that is already in resources will recordiung using the a copy of the file as base (integrating calls to the existing one).
 */
let bundle = Bundle.main
SuperMock.beginRecording(bundle)

getTheUKApplePage()

var fileBundle = SuperMockResponseHelper.bundleForMocks
/*:

 ### For a default url session this is exactly what need to happen in order of start to record, if your playground is playing correctly the console should have shown at this point the location of the recorded file, something similar to:
 
 Recording mocks at: /var/folders/1v/mlx9_4cn5sv9pt5g3jcm4vs40000gq/T/com.apple.dt.Xcode.pg/containers/com.apple.dt.playground.stub.iOS_Simulator.SuperMock-69C1D0E6-CD17-4958-9B6D-FB91C7C946F9/Documents/Mocks.plist

 ### This is the file that describe the mocks to the system it is a common plist file let's take a look to the structure. The file contains mime accepted tipes, and mocks. Inside mocks you can find GET, POST, HEAD, PUT. Inside Get all the GETs calls grouped by url. In our example http://apple.com/uk would record one call so far... but we are reading the resource file of the playground that has 3
*/
if let path = bundle.path(forResource: "Mocks", ofType: "plist") {
    let mocks = NSDictionary(contentsOf: URL(fileURLWithPath: path))?["mocks"] as? [String: Any]
    let getCalls = mocks?["GET"] as? [String: Any]
    let appleCalls = getCalls?["http://apple.com/uk"] as? [[String:String]]
    appleCalls?.count
}
/*:

 ### The recorded response body file path will look like this:

    /var/folders/1v/mlx9_4cn5sv9pt5g3jcm4vs40000gq/T/com.apple.dt.Xcode.pg/containers/com.apple.dt.playground.stub.iOS_Simulator.SuperMock-69C1D0E6-CD17-4958-9B6D-FB91C7C946F9/Documents/%22http%3A%2F%2Fapple.com%2Fuk%22-0.txt


 ### The recorded response headers file path will look like this:

    /var/folders/1v/mlx9_4cn5sv9pt5g3jcm4vs40000gq/T/com.apple.dt.Xcode.pg/containers/com.apple.dt.playground.stub.iOS_Simulator.SuperMock-69C1D0E6-CD17-4958-9B6D-FB91C7C946F9/Documents/%22http%3A%2F%2Fapple.com%2Fuk%22-1.txt
 */
/*:
 ### Make multiple times the same call would end up just adding more entries to the key related to the url that we are calling.
 */
getTheUKApplePage()
SuperMock.endRecording()
/*:
 ### In case you are using a URLSession that is not the default one you need to register the protocols once the URLSession is created.
 */
let customSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "SuperMockBackgroundConfiguration")
let customURLSession = URLSession(configuration: customSessionConfiguration)

SuperMock.beginRecording(bundle, configuration: customSessionConfiguration, session: customURLSession)


fileBundle = SuperMockResponseHelper.bundleForMocks
/*:
 ### always remember to terminate the recording, it is good practice.
 */
SuperMock.endRecording()
/*:
 ### Everything from now on will behave normally and the calls will hit the network.
 */
get("http://www.danieleforlani.net")
/*:
### Now that we have the recorded values we ca use and replay them
  ### [Next Page >>](@next)

 */
