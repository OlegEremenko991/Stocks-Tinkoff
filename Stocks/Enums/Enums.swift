//
//  ErrorType.swift
//  Stocks
//
//  Created by Олег Еременко on 11.10.2020.
//  Copyright © 2020 Oleg Eremenko. All rights reserved.
//

import Foundation

enum ErrorType: String, Error {
    case companiesError = "Could not load companies data"
    case quoteError = "Could not load quote data"
    case imageError = "Could not load image"
    case invalidData = "Invalid data"
    case requestFailed = "Request failed - check your internet connection"
}

enum RequestType {
    case requestCompanies(String?, String?)
    case requestQoute(String?, String?, String?)
    case requestLogo(String?, String?, String?)
    
    var url: URL? {
        return URL(string: stringURL)
    }
    
    var stringURL: String {
        switch self {
        case .requestCompanies(let defaultURL, let token):
            return defaultURL! + "market/list/mostactive?token=" + token!
        case .requestQoute(let defaultURL, let symbol, let token):
            return defaultURL! + symbol! + "/quote?token=" + token!
        case .requestLogo(let defaultURL, let symbol, let token):
            return defaultURL! + symbol! + "/logo?token=" + token!
        }
    }
}
