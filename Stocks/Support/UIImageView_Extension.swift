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
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.image = UIImage(named: "brand")
                }
            }
        }
    }
    
    // Set up default image and properties
    func defaultSetup() {
        self.image = UIImage(named: "brand")
        self.backgroundColor = .white
        self.layer.cornerRadius = 10
    }
}


