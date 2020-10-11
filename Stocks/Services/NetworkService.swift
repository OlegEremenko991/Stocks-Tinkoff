//
//  NetworkService.swift
//  Stocks
//
//  Created by Олег Еременко on 11.10.2020.
//  Copyright © 2020 Oleg Eremenko. All rights reserved.
//

import UIKit

public final class NetworkService {

    static func loadCompanies(token: String, completion: @escaping (Result<[Company], ErrorType>) -> ()) {
        let defaultURL = "https://cloud.iexapis.com/stable/stock/"
        var requestURL: URL?
        var resultArray = [Company]()
        
        requestURL = RequestType.requestCompanies(defaultURL, token).url
        
        let task = URLSession.shared.dataTask(with: requestURL!) { (data, response, error) in
            guard let data = data, (response as? HTTPURLResponse)?.statusCode == 200, error == nil else {
                completion(.failure(.requestFailed))
                return
            }
            do {
                let dataFromJson = try JSONDecoder().decode([Company].self, from: data)
                resultArray = dataFromJson
                completion(.success(resultArray))
            } catch {
                completion(.failure(.companiesError))
            }
        }
        task.resume()
    }
    
    static func loadQuote(token: String, symbol: String, completion: @escaping (Result<Quote, ErrorType>) -> ()) {
        let defaultURL = "https://cloud.iexapis.com/stable/stock/"
        var requestURL: URL?
        var result = Quote()
        
        requestURL = RequestType.requestQoute(defaultURL, symbol, token).url
        
        let task = URLSession.shared.dataTask(with: requestURL!) { (data, response, error) in
            guard let data = data, (response as? HTTPURLResponse)?.statusCode == 200, error == nil else {
                completion(.failure(.requestFailed))
                return
            }
            do {
                let dataFromJson = try JSONDecoder().decode(Quote.self, from: data)
                result = dataFromJson
                completion(.success(result))
            } catch {
                completion(.failure(.quoteError))
            }
        }
        task.resume()
    }
    
    static func loadLogo(token: String, symbol: String, completion: @escaping (Result<ImageData, ErrorType>) -> ()) {
        let defaultURL = "https://cloud.iexapis.com/stable/stock/"
        var requestURL: URL?
        var result = ImageData()
        
        requestURL = RequestType.requestLogo(defaultURL, symbol, token).url
        
        let task = URLSession.shared.dataTask(with: requestURL!) { (data, response, error) in
            guard let data = data, (response as? HTTPURLResponse)?.statusCode == 200, error == nil else {
                completion(.failure(.requestFailed))
                return
            }
            do {
                let dataFromJson = try JSONDecoder().decode(ImageData.self, from: data)
                result = dataFromJson
                completion(.success(result))
            } catch {
                completion(.failure(.imageError))
            }
        }
        task.resume()
    }

}


            
