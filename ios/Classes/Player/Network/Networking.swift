//
//  Network.swift
//  Pods
//
//  Created by Udevs on 07/10/22.
//

import Foundation
import UIKit

enum NetworkError : Error {
    case NoDataAvailable
    case CanNotProcessData
}


struct Networking {
    static let sharedInstance = Networking()
    let session = URLSession.shared
    
    func getMegogoStream(_ baseUrl:String, token:String, sessionId:String, parameters: [String: String]) -> Result<MegogoStreamResponse, NetworkError> {
        var components = URLComponents(string: baseUrl)!
        components.queryItems = parameters.map { (key, value) in
            URLQueryItem(name: key, value: value)
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue(sessionId, forHTTPHeaderField:"SessionId" )
        
        var result: Result<MegogoStreamResponse, NetworkError>!
        let semaphore = DispatchSemaphore(value: 0)
        session.dataTask(with: request){data,_,_ in
            guard let json = data else{
                result = .failure(.NoDataAvailable)
                return
            }
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(MegogoStreamResponse.self, from: Data(json))
                result = .success(response)
            }
            catch{
                result = .failure(.CanNotProcessData)
            }
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(wallTimeout: .distantFuture)
        return result
    }
    
    func getChannel(_ baseUrl: String, token: String, sessionId: String, parameters: [String: String]) -> Result<ChannelResponse, NetworkError> {
        var components = URLComponents(string: baseUrl)!
        components.queryItems = parameters.map { (key, value) in
            URLQueryItem(name: key, value: value)
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue(sessionId, forHTTPHeaderField: "SessionId")
        
        var result: Result<ChannelResponse, NetworkError>!
        let semaphore = DispatchSemaphore(value: 0)
        session.dataTask(with: request){data,_,__ in
            guard let json = data else{
                result = .failure(.NoDataAvailable)
                return
            }
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(ChannelResponse.self, from: Data(json))
                print("response")
                print(response)
                result = .success(response)
            }
            catch{
                result = .failure(.CanNotProcessData)
            }
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(wallTimeout: .distantFuture)
        return result
    }
    
    func getStreamUrl(_ baseUrl: String) -> Result<String, NetworkError> {
        var components = URLComponents(string: baseUrl)!
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        
        var result: Result<String, NetworkError>!
        let semaphore = DispatchSemaphore(value: 0)
        session.dataTask(with: request){data,_,__ in
            guard let json = data else{
                result = .failure(.NoDataAvailable)
                return
            }
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(String.self, from: Data(json))
                result = .success(response)
            }
            catch{
                result = .failure(.CanNotProcessData)
            }
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(wallTimeout: .distantFuture)
        return result
    }
    
    func getPremierStream(_ baseUrl:String, token:String, sessionId:String) -> Result<PremierStreamResponse, NetworkError> {
        let url = URL(string: baseUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue(sessionId, forHTTPHeaderField: "SessionId")
    
        var result: Result<PremierStreamResponse, NetworkError>!
        let semaphore = DispatchSemaphore(value: 0)
        session.dataTask(with: request){data,_,_ in
            guard let json = data else{
                result = .failure(.NoDataAvailable)
                return
            }
            do{
                let decoder = JSONDecoder()
                let response = try decoder.decode(PremierStreamResponse.self, from: Data(json))
                result = .success(response)
            }
            catch{
                result = .failure(.CanNotProcessData)
            }
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(wallTimeout: .distantFuture)
        return result
    }
}
