//
//  NetworkService.swift
//  Stocks
//
//  Created by Олег Еременко on 11.10.2020.
//  Copyright © 2020 Oleg Eremenko. All rights reserved.
//

import UIKit

public final class NetworkService {
    
    static func loadData<T: Decodable>(decodingType: T.Type, token: String, symbol: String? = nil, completion: @escaping (Result<T, ErrorType>) -> ()) {
        let defaultURL = "https://cloud.iexapis.com/stable/stock/"
        var requestURL: URL?
        var resultData: T?
        var errorType: ErrorType!
        
        switch decodingType {
        case is Quote.Type:
            requestURL = RequestType.requestQoute(defaultURL, symbol, token).url
            errorType = .quoteError
        case is ImageData.Type:
            requestURL = RequestType.requestLogo(defaultURL, symbol, token).url
            errorType = .imageError
        default:
            requestURL = RequestType.requestCompanies(defaultURL, token).url
            errorType = .companiesError
        }
        
        let task = URLSession.shared.dataTask(with: requestURL!) { (data, response, error) in
            guard let data = data, (response as? HTTPURLResponse)?.statusCode == 200, error == nil else {
                completion(.failure(.requestFailed))
                return
            }
            do {
                let dataFromJson = try JSONDecoder().decode(decodingType, from: data)
                resultData = dataFromJson
                guard let resultData = resultData else {
                    completion(.failure(.invalidData))
                    return
                }
                completion(.success(resultData))
            } catch {
                completion(.failure(errorType))
            }
        }
        task.resume()
    }

}


            
