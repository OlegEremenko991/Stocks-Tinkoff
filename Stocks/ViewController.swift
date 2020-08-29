//
//  ViewController.swift
//  Stocks
//
//  Created by Олег Еременко on 28.08.2020.
//  Copyright © 2020 Oleg Eremenko. All rights reserved.
//

import UIKit
import MessageUI

class ViewController: UIViewController {
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    
    private lazy var devEmail = "support_stocks@gmail.com"
// MARK: Companies for UIPickerView
//
//    private lazy var companies = [
//        "Apple": "AAPL",
//        "Microsoft": "MSFT",
//        "Google": "GOOG",
//        "Amazon": "AMZN",
//        "Facebook": "FB"
//    ]
    
    private var companiesArray = [Company]()

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
                self.showALert(title: "Network error", message: "Check your internet connection and tap OK to reload company data")
                print("Network error! Could not get quote data")
            }
        }
        
        dataTask1.resume()
        
        let dataTask2 = URLSession.shared.dataTask(with: url2) { (data, response, error) in
            if let data = data, (response as? HTTPURLResponse)?.statusCode == 200, error == nil {
                self.parseImage(from: data)
            } else {
                print("Network error! Could not get image URL")
            }
        }
        
        dataTask2.resume()
    }
    
    private func requestCompanies() {
        let token = "sk_2300dc06c77a4de5a7b9b4301594f733"
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/market/list/mostactive?token=\(token)") else { return }
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data, (response as? HTTPURLResponse)?.statusCode == 200, error == nil {
                self.parseCompanies(from: data)
            } else {
                self.showALert(title: "Network error", message: "Check your internet connection and tap OK to reload companies")
                print("Network error! Could not get companies data")
            }
        }
        
        dataTask.resume()
        
        return
    }
    
    private func parseCompanies(from data: Data) {
        let jsonData = try? JSONDecoder().decode([Company].self, from: data)
        guard let companiesData = jsonData else { return }
        companiesArray = companiesData
        DispatchQueue.main.async {
            self.companyPickerView.reloadAllComponents()
            self.requestQuoteUpdate()
        }
        
    }
    
    private func parseQuote(from data: Data) {
        let jsonErrorTitle = "Invalid data"
        let jsonErrorMessage = "Tap OK to send a bug report"
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double else {
                    print("Invalid JSON")
                    return showALert(title: jsonErrorTitle, message: jsonErrorMessage)
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.displayStockInfo(companyName: companyName, companySymbol: companySymbol, price: price, priceChange: priceChange)
            }
        } catch  {
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    
    private func parseImage(from data: Data) {
        let jsonErrorTitle = "Invalid data"
        let jsonErrorMessage = "Tap OK to send a bug report"
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let stringURL = json["url"] as? String,
                let imageURL = URL(string: stringURL) else {
                    print("Invalid JSON")
                    return showALert(title: jsonErrorTitle, message: jsonErrorMessage)
            }
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
        if priceChange > 0 {
            priceChangeLabel.textColor = .green
        } else if priceChange < 0 {
            priceChangeLabel.textColor = .red
        }
    }
    
    private func requestQuoteUpdate() {
        activityIndicator.startAnimating()
        let labelArray = [companyNameLabel, companySymbolLabel, priceLabel, priceChangeLabel]
        for x in labelArray {
            x?.text = "..."
            x?.textColor = UIColor { tc in
                switch tc.userInterfaceStyle {
                case .dark:
                    return UIColor.white
                default:
                    return UIColor.black
                }
            }
        }
        
        logoImageView.image = UIImage(named: "brand")
        logoImageView.backgroundColor = .white
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = companiesArray[selectedRow].symbol
        requestQuote(for: selectedSymbol)
    }
    
    // MARK: - ALert
    
    private func showALert(title: String, message: String){
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] action in
                if title != "Network error" {
                    let subject = "Report a problem in app"
                    self?.sendEmail(subject: subject)
                } else {
                    self?.requestQuoteUpdate()
                }
            }
            alert.addAction(okAction)
            
            self.present(alert, animated: true)
            self.activityIndicator.stopAnimating()
        }

    }
    
    // MARK: - Report a bug Email
    
    private func sendEmail(subject: String) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([devEmail])
            mail.setMessageBody("<p> Invalid data error in Alert title </p>", isHTML: true)
            mail.setSubject(subject)
            present(mail, animated: true)
        } else {
            print("error")
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        
        activityIndicator.hidesWhenStopped = true
        
        requestCompanies()
    }
    
}

// MARK: - UIPickerViewDataSource

extension ViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return companiesArray.count
    }
}

// MARK: - UIPickerViewDelegate

extension ViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        return Array(companies.keys)[row]
        return companiesArray[row].companyName
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        requestQuoteUpdate()
    }
}

// MARK: - MessageUI

extension ViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
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
