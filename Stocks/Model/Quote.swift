//
//  Quote.swift
//  Stocks
//
//  Created by Олег Еременко on 29.08.2020.
//  Copyright © 2020 Oleg Eremenko. All rights reserved.
//

import Foundation

struct Quote: Codable {
    var companyName: String
    var symbol: String
    var latestPrice: Double
    var change: Double
}
