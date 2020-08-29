//
//  UIImageView_Extension.swift
//  Stocks
//
//  Created by Олег Еременко on 29.08.2020.
//  Copyright © 2020 Oleg Eremenko. All rights reserved.
//

import UIKit

// MARK: Load image

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.main.async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    self?.image = image
                }
            }
        }
    }
}
