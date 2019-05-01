// If you cannot see this file correctly go on the menu Editor -> Show Render Markup.
// Build the project at least once before run the playground.
/*:

 # SuperMock: guide to use
 (Simple guide that let you understand easily how to use the Supermock framework)

 */
/*:
 ### If you do not have mocking data, but you have your network calls already in place the easiest thing to do is use the recording feature and adjust later the responses to your desired behaviour. Take a look to the example app or to the recording playground to see where and how the recorded resposes are saved. The plist file that record the mocks will contain all the network calls with a distinction between the response headers and the response body. The Supermock framework support multiple calls to the same url, this means that multiple calls to the same url will be recorded multiple times in different files.
 ### If you want to record your network data from live network calls you can start with:
  ## [Recording network data](RecordingNetworkData)
 */
/*:
 ### If you want to play data that you have recorded or populated by yourself in the mock file start with:
 ## [Playing network data](PlayingNetworkData)
 */



