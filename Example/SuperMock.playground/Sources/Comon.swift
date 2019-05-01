import Foundation
@testable import SuperMock

public func getTheUKApplePage(completion: ((Int, Int, Bool) -> Void)? = nil) {
    get("http://apple.com/uk") { (data, response, error) in
        completion?(data?.count ?? 0, (response as! HTTPURLResponse).statusCode, error == nil)
    }
}

public func get(_ urlString: String, completion: ((Data?, URLResponse?, Error?)-> Void)? = nil) {
    let urlSession = URLSession.shared
    let url = URL(string: urlString)!
    let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 5.0)

    let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
        if let validData = data {
            print("I have received \(validData.count) bytes of data")
        }
        if let validResponse = response as? HTTPURLResponse {
            print("I have a valid response \(validResponse.statusCode)")
        }
        if let validError = error {
            print("I have received a valid error \(validError)")
        }
        completion?(data, response, error)
    }
    dataTask.resume()
}
