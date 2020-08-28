//
//  ViewController.swift
//  Stocks
//
//  Created by Олег Еременко on 28.08.2020.
//  Copyright © 2020 Oleg Eremenko. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    
// MARK: Companies for UIPickerView
    
    private lazy var companies = [
        "Apple": "AAPL",
        "Microsoft": "MSFT",
        "Google": "GOOG",
        "Amazon": "AMZN",
        "Facebook": "FB"
    ]

// MARK: Request stocks data and image
    
    private func requestQuote(for symbol: String) {
        let token = "sk_2300dc06c77a4de5a7b9b4301594f733"
        guard let url1 = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(token)"),
            let url2 = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/logo?token=\(token)") else {
            return
        }
        
        let dataTask1 = URLSession.shared.dataTask(with: url1) { (data, response, error) in
            if let data = data, (response as? HTTPURLResponse)?.statusCode == 200, error == nil {
                self.parseQuote(from: data)
            } else {
                print("Network error!")
            }
        }
        
        dataTask1.resume()
        
        let dataTask2 = URLSession.shared.dataTask(with: url2) { (data, response, error) in
            if let data = data, (response as? HTTPURLResponse)?.statusCode == 200, error == nil {
                self.parseImage(from: data)
            } else {
                print("Network error!")
            }
        }
        
        dataTask2.resume()
    }
    
    private func parseQuote(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double else { return print("Invalid JSON") }
            
            DispatchQueue.main.async { [weak self] in
                self?.displayStockInfo(companyName: companyName, companySymbol: companySymbol, price: price, priceChange: priceChange)
            }
        } catch  {
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    
    private func parseImage(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let stringURL = json["url"] as? String,
                let imageURL = URL(string: stringURL) else { return print("Invalid JSON") }
            
                logoImageView.load(url: imageURL)
        } catch  {
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    
    private func displayStockInfo(companyName: String, companySymbol: String, price: Double, priceChange: Double) {
        activityIndicator.stopAnimating()
        companyNameLabel.text = companyName
        companySymbolLabel.text = companySymbol
        priceLabel.text = "\(price)"
        priceChangeLabel.text = "\(priceChange)"
    }
    
    private func requestQuoteUpdate() {
        activityIndicator.startAnimating()
        
        let labelArray = [companyNameLabel, companySymbolLabel, priceLabel, priceChangeLabel]
        for x in labelArray {
            x?.text = "..."
        }
        logoImageView.image = UIImage(named: "brand")
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(companies.values)[selectedRow]
        requestQuote(for: selectedSymbol)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        
        activityIndicator.hidesWhenStopped = true
        
        requestQuoteUpdate()
    }
    
}

// MARK: - UIPickerViewDataSource

extension ViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return companies.keys.count
    }
}

// MARK: - UIPickerViewDelegate

extension ViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(companies.keys)[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        requestQuoteUpdate()
    }
}

// MARK: - Load image extension

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
