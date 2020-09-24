//
//  ViewController.swift
//  Stocks
//
//  Created by Олег Еременко on 28.08.2020.
//  Copyright © 2020 Oleg Eremenko. All rights reserved.
//

import UIKit
import MessageUI

final class ViewController: UIViewController {
    
// MARK: IBOutlets
    
    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var hintLabel: UILabel!
    
// MARK: Private properties
    
    private var tempErrorText = "" // stores error text for report
    private var symbol: String? // symbol for data request
    private let token = "sk_2300dc06c77a4de5a7b9b4301594f733" // token to access API data
    private let devEmail = "o.n.eremenko@gmail.com" // support email
    
    // Companies for UIPickerView
    private var companiesArray: [Company]?
    
    // Data for the selected company
    private var quoteData: Quote?
    private var imageData: ImageData?
    
// MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        requestData(dataType: .companies)
    }
    
// MARK: Private methods
    
    private func setupView() {
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        
        activityIndicator.hidesWhenStopped = true
        
        hintLabel.isHidden = true
        reloadButton.isHidden = true
    }
    
    private func requestData(dataType: DataType) {
        var stringURL = ""
        var actionType: ActionType
        var errorType: ErrorType
        switch dataType {
        case .companies:
            stringURL = "https://cloud.iexapis.com/stable/stock/market/list/mostactive?token=\(token)"
            actionType = .parseCompanies
            errorType = .noCompanies
        case .quote:
            guard let symbol = symbol else { return }
            stringURL = "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(token)"
            actionType = .parseQuote
            errorType = .noQuote
        case .logo:
            guard let symbol = symbol else { return }
            stringURL = "https://cloud.iexapis.com/stable/stock/\(symbol)/logo?token=\(token)"
            actionType = .parseLogo
            errorType = .noLogo
        }
        
        guard let url = URL(string: stringURL) else { return }
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data, (response as? HTTPURLResponse)?.statusCode == 200, error == nil {
                switch actionType {
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
                guard companiesArray != nil else { return }
                companiesArray = companiesArray?.sorted(by: { $0.companyName < $1.companyName }) // sort companies by name
                DispatchQueue.main.async { [weak self] in
                    self?.companyPickerView.reloadAllComponents()
                    self?.requestQuoteUpdate()
                }
            case .quote:
                let dataFromJson = try jsonDecoder.decode(Quote.self, from: data)
                quoteData = dataFromJson
                guard let quoteData = quoteData else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.displayStockInfo(data: quoteData)
                }
            case .logo:
                let dataFromJson = try jsonDecoder.decode(ImageData.self, from: data)
                imageData = dataFromJson
                guard let imageData = imageData else { return }
                let imageURL = URL(string: imageData.url)
                logoImageView.load(url: imageURL!)
            }
        } catch {
            print(error)
            tempErrorText = "\(error)"
            showALert(errorType: .invalidData)
        }
    }
    
    // Display parsed data on the screen
    private func displayStockInfo(data: Quote) {
        activityIndicator.stopAnimating()

        companyNameLabel.text = data.companyName
        companySymbolLabel.text = data.symbol
        priceLabel.text = "\(data.latestPrice)"
        priceChangeLabel.text = "\(data.change)"
        
        // Change label text color depending on "change" value
        if data.change > 0 {
            priceChangeLabel.textColor = .systemGreen
        } else if data.change < 0 {
            priceChangeLabel.textColor = .systemRed
        }
    }
    
    private func requestQuoteUpdate() {
        activityIndicator.startAnimating()
        companyNameLabel.numberOfLines = 2
        logoImageView.defaultSetup() // setup default image and properties
        
        updateLabels()
        hintLabel.isHidden = false
        reloadButton.isHidden = true
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        symbol = companiesArray?[selectedRow].symbol

        requestData(dataType: .quote)
        requestData(dataType: .logo)
    }
    
    // Update labels text and text color
    private func updateLabels() {
        let labelArray = [companyNameLabel, companySymbolLabel, priceLabel, priceChangeLabel]
        for x in labelArray {
            x?.text = "-"
            x?.textColor = UIColor { tc in
                switch tc.userInterfaceStyle {
                case .dark:
                    return .white
                default:
                    return .black
                }
            }
        }
    }
    
    private func showALert(errorType: ErrorType){
        var titleText = ""
        var messageText = "Check your internet connection"
        var solution: SolutionType
        
        switch errorType {
        case .noCompanies:
            titleText = "List of companies is not available"
            solution = .reloadCompanies
        case .noQuote:
            titleText = "Company quotes missing"
            solution = .reloadStocksData
        case .noLogo:
            titleText = "Company logo is not available"
            solution = .reloadLogo
        case .invalidData:
            titleText = "Invalid data"
            messageText = "Please report this issue"
            solution = .report
        }
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: titleText, message: messageText, preferredStyle: .alert)
            let ignoreAction = UIAlertAction(title: "Ignore", style: .destructive) { [weak self] action in
                DispatchQueue.main.async {
                    self?.reloadButton.isHidden = false
                }
            }
            let okAction = UIAlertAction(title: "Reload", style: .default) { [weak self] action in
                switch solution {
                case .reloadCompanies:
                    self?.requestData(dataType: .companies)
                case .reloadStocksData:
                    self?.requestData(dataType: .quote)
                    self?.requestData(dataType: .logo)
                case .reloadLogo:
                    self?.requestData(dataType: .logo)
                case .report:
                    let subject = "Report a problem in app"
                    self?.sendEmail(with: subject)
                }
            }
            alert.addAction(okAction)
            alert.addAction(ignoreAction)
            
            self.present(alert, animated: true)
            self.activityIndicator.stopAnimating()
        }
    }
    
    // Report an issue
    private func sendEmail(with subject: String) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([devEmail])
            mail.setMessageBody("<p> Error: \(tempErrorText) </p>", isHTML: true)
            mail.setSubject(subject)
            present(mail, animated: true)
        } else {
            print("error")
        }
    }
    
// MARK: IBActions
    
    @IBAction func reloadButtonTapped(_ sender: UIButton) {
        requestData(dataType: .companies)
    }
    
}

// MARK: UIPickerViewDataSource

extension ViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return companiesArray?.count ?? 1
    }
    
    // Customize label inside picker view
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.text = companiesArray?[row].companyName
        label.sizeToFit()
        return label
    }
}

// MARK: UIPickerViewDelegate

extension ViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return companiesArray?[row].companyName
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        requestQuoteUpdate()
    }
}

// MARK: MFMailComposeViewControllerDelegate

extension ViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
