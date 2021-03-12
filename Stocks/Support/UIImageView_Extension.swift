//
//  UIImageView_Extension.swift
//  Stocks
//
//  Created by Олег Еременко on 29.08.2020.
//  Copyright © 2020 Oleg Eremenko. All rights reserved.
//

import UIKit

extension UIImageView {
    
    // Load image from URL on background thread and update UI on main thread
    func load(url: URL) {
        let queue = DispatchQueue.global(qos: .utility)
        queue.async {
            if let data = try? Data(contentsOf: url) {
                DispatchQueue.main.async { [weak self] in
                    self?.image = UIImage(data: data)
                }
            }
        }
    }
    
    /// Set up default image and properties
    func defaultSetup() {
        image = UIImage(named: "brand")
        backgroundColor = .white
        layer.cornerRadius = 10
    }
}


