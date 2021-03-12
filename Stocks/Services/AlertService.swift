//
//  AlertService.swift
//  Stocks
//
//  Created by Олег Еременко on 11.10.2020.
//  Copyright © 2020 Oleg Eremenko. All rights reserved.
//

import UIKit

final class AlertService {
    
    static func customAlert(title: String, message: String, style: UIAlertController.Style? = nil, actions: [UIAlertAction]) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style ?? .alert)
        for action in actions { alertController.addAction(action) }
        return alertController
    }
    
}
