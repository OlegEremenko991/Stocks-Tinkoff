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
    
    private var symbol: String?
    private let token = "sk_2300dc06c77a4de5a7b9b4301594f733"
    private lazy var devEmail = "support_stocks@gmail.com"
    
// MARK: Companies for UIPickerView
    
    private var companiesArray: [Company]?
    
// MARK: Data for selected company
    
    private var quoteData: Quote?
    private var imageData: ImageData?

// MARK: Request stocks data and image
    
    private func requestData(dataType: DataType) {
        var stringURL = ""
        var jsonType: JsonType
        var errorType: ErrorType
        switch dataType {
        case .companies:
            stringURL = "https://cloud.iexapis.com/stable/stock/market/list/mostactive?token=\(token)"
            jsonType = .parseCompanies
            errorType = .companies
        case .quote:
            guard let symbol = symbol else { return }
            stringURL = "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(token)"
            jsonType = .parseQuote
            errorType = .stocksData
        case .logo:
            guard let symbol = symbol else { return }
            stringURL = "https://cloud.iexapis.com/stable/stock/\(symbol)/logo?token=\(token)"
            jsonType = .parseLogo
            errorType = .companyLogo
        }
        
        guard let url = URL(string: stringURL) else { return }
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data, (response as? HTTPURLResponse)?.statusCode == 200, error == nil {
                switch jsonType {
                case .parseCompanies:
                    self.parseData(from: data, dataType: .companies)
                case .parseQuote:
                    self.parseData(from: data, dataType: .quote)
                case .parseLogo:
                    self.parseData(from: data, dataType: .logo)
                }
            } else {
                self.showALert(errorType: errorType)
                print("Network error!")
            }
        }
        
        dataTask.resume()
    }
    
    private func parseData(from data: Data, dataType: DataType) {
        let jsonDecoder = JSONDecoder()
        
        do {
            switch dataType {
            case .companies:
                let dataFromJson = try jsonDecoder.decode([Company].self, from: data)
                companiesArray = dataFromJson
                guard companiesArray != nil else { return showALert(errorType: .companies) }
                DispatchQueue.main.async {
                    self.companyPickerView.reloadAllComponents()
                    self.requestQuoteUpdate()
                }
            case .quote:
                let dataFromJson = try jsonDecoder.decode(Quote.self, from: data)
                quoteData = dataFromJson
                guard let quoteData = quoteData else { return showALert(errorType: .invalidData) }
                DispatchQueue.main.async { [weak self] in
                    self?.displayStockInfo(data: quoteData)
                }
            case .logo:
                let dataFromJson = try jsonDecoder.decode(ImageData.self, from: data)
                imageData = dataFromJson
                guard let imageData = imageData else { return showALert(errorType: .invalidData) }
                let imageURL = URL(string: imageData.url)
                logoImageView.load(url: imageURL!)
            }
        } catch {
            print(error)
        }

    }
    
//    private func parseQuote(from data: Data) {
//        do {
//            let jsonObject = try JSONSerialization.jsonObject(with: data)
//
//            guard
//                let json = jsonObject as? [String: Any],
//                let companyName = json["companyName"] as? String,
//                let companySymbol = json["symbol"] as? String,
//                let price = json["latestPrice"] as? Double,
//                let priceChange = json["change"] as? Double else {
//                    print("Invalid JSON")
//                    return showALert(errorType: .invalidData)
//            }
//
//            DispatchQueue.main.async { [weak self] in
//                self?.displayStockInfo(companyName: companyName, companySymbol: companySymbol, price: price, priceChange: priceChange)
//            }
//        } catch  {
//            print("JSON parsing error: " + error.localizedDescription)
//        }
//    }
    

//    private func displayStockInfo(companyName: String, companySymbol: String, price: Double, priceChange: Double) {
//        activityIndicator.stopAnimating()
//        companyNameLabel.text = companyName
//        companySymbolLabel.text = companySymbol
//        priceLabel.text = "\(price)"
//        priceChangeLabel.text = "\(priceChange)"
//        if priceChange > 0 {
//            priceChangeLabel.textColor = .green
//        } else if priceChange < 0 {
//            priceChangeLabel.textColor = .red
//        }
//    }
    
    private func displayStockInfo(data: Quote) {
        activityIndicator.stopAnimating()
        companyNameLabel.text = data.companyName
        companySymbolLabel.text = data.symbol
        priceLabel.text = "\(data.latestPrice)"
        priceChangeLabel.text = "\(data.change)"
        
        if data.change > 0 {
            priceChangeLabel.textColor = .green
        } else if data.change < 0 {
            priceChangeLabel.textColor = .red
        }
    }
    
    private func requestQuoteUpdate() {
        activityIndicator.startAnimating()
        companyNameLabel.numberOfLines = 2
        logoImageView.image = UIImage(named: "brand")
        logoImageView.backgroundColor = .white
        logoImageView.layer.cornerRadius = 10
        
        updateLabels()
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        symbol = companiesArray?[selectedRow].symbol

        requestData(dataType: .quote)
        requestData(dataType: .logo)
    }
    
    private func updateLabels() {
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
    }
    
    // MARK: - ALert
    
    private func showALert(errorType: ErrorType){
        var titleText = ""
        var messageText = ""
        var solve: SolutionType
        
        switch errorType {
        case .companies:
            titleText = "Companies list not loaded"
            messageText = "Check your internet connection and tap OK to reload"
            solve = .reloadCompanies
        case .stocksData:
            titleText = "Company stocks data not loaded"
            messageText = "Check your internet connection and tap OK to reload"
            solve = .reloadStocksData
        case .companyLogo:
            titleText = "Company logo not loaded"
            messageText = "Check your internet connection and tap OK to reload"
            solve = .reloadLogo
        case .invalidData:
            titleText = "Invalid data"
            messageText = "Please report this issue"
            solve = .report
        }
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: titleText, message: messageText, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] action in
                switch solve {
                case .reloadCompanies:
                    self?.requestData(dataType: .companies)
                case .reloadStocksData:
                    self?.requestData(dataType: .quote)
                case .reloadLogo:
                    self?.requestData(dataType: .logo)
                case .report:
                    let subject = "Report a problem in app"
                    self?.sendEmail(subject: subject)
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
        
        requestData(dataType: .companies)
    }
    
}

// MARK: - UIPickerViewDataSource

extension ViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return companiesArray?.count ?? 1
    }
}

// MARK: - UIPickerViewDelegate

extension ViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return companiesArray?[row].companyName
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
