//
//  StockData.swift
//  Stocks
//
//  Created by Олег Еременко on 28.08.2020.
//  Copyright © 2020 Oleg Eremenko. All rights reserved.
//

import Foundation

struct StockData: Codable {
    var companyName: String
    var symbol: String
    var latestPrice: Double
    var change: Double
}
