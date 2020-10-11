//
//  Company.swift
//  Stocks
//
//  Created by Олег Еременко on 11.10.2020.
//  Copyright © 2020 Oleg Eremenko. All rights reserved.
//

struct Company: Codable {
    var symbol: String
    var companyName: String
}

struct Quote: Codable {
    var companyName: String
    var symbol: String
    var latestPrice: Double
    var change: Double
}

struct ImageData: Codable {
    var url: String
}
