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
    
    private var alertController: UIAlertController?
    private var error: ErrorType?
    private let devEmail = "o.n.eremenko@gmail.com" // support email
    private var tempErrorText = "" // stores error text for report
    
    private var symbol: String? // symbol for data request
    private let token = "sk_2300dc06c77a4de5a7b9b4301594f733" // token to access API data
    
    private var companiesArray: [Company]? // Companies for UIPickerView
    
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
        var actionType: RequestType
        switch dataType {
        case .companies:
            stringURL = "https://cloud.iexapis.com/stable/stock/market/list/mostactive?token=\(token)"
            actionType = .parseCompanies
            error = .noCompanies
        case .quote:
            guard let symbol = symbol else { return }
            stringURL = "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(token)"
            actionType = .parseQuote
            error = .noQuote
        case .logo:
            guard let symbol = symbol else { return }
            stringURL = "https://cloud.iexapis.com/stable/stock/\(symbol)/logo?token=\(token)"
            actionType = .parseLogo
            error = .noLogo
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
                guard let error = self.error else { return }
                self.showALert(errorType: error)
                print(error.rawValue)
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
        var messageText = ""
        
        switch errorType {
        case .noCompanies:
            messageText = "List of companies is not available"
        case .noQuote:
            messageText = "Company quotes missing"
        case .noLogo:
            messageText = "Company logo is not available"
        case .invalidData:
            messageText = "Please report this issue"
        }
        
        DispatchQueue.main.async {
            let reloadAction = UIAlertAction(title: "Reload", style: .default, handler: { [weak self] _ in
                switch self?.error {
                case .noCompanies:
                    self?.requestData(dataType: .companies)
                case .noQuote:
                    self?.requestData(dataType: .quote)
                    self?.requestData(dataType: .logo)
                case .noLogo:
                    self?.requestData(dataType: .logo)
                case .invalidData:
                    let subject = "Report a problem in app"
                    self?.sendEmail(with: subject)
                case .none:
                    return
                }
                self?.alertController = nil
            })
            let ignoreAction = UIAlertAction(title: "Ignore", style: .destructive, handler: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.reloadButton.isHidden = false
                }
            })

            // Prevent from showing multiple alert controllers
            guard self.alertController == nil else { return }

            self.alertController = AlertService.customAlert(title: "Error", message: messageText, errorType: errorType, actions: [reloadAction, ignoreAction])

            guard let alert = self.alertController else { return }

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
