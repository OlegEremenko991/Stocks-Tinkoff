//
//  ErrorType.swift
//  Stocks
//
//  Created by Олег Еременко on 11.10.2020.
//  Copyright © 2020 Oleg Eremenko. All rights reserved.
//

enum ErrorType: String, Error {
    case noCompanies = "No companies data"
    case noQuote = "No quote data"
    case noLogo = "No logo data"
    case invalidData = "Invalid data"
}

enum DataType {
    case companies
    case quote
    case logo
}

enum RequestType {
    case parseCompanies
    case parseQuote
    case parseLogo
}
