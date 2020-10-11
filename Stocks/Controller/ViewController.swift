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
    private let devEmail = "o.n.eremenko@gmail.com" // support email
    private var tempErrorText = "" // stores error text for report
    
    private var symbol: String? // symbol for data request
    private let token = "sk_2300dc06c77a4de5a7b9b4301594f733" // token to access API data
    
    private var companiesArray = [Company]() // Companies for UIPickerView
    
// MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        requestData(requestType: .requestCompanies(nil, nil))
    }
    
// MARK: Private methods
    
    private func setupView() {
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        
        activityIndicator.hidesWhenStopped = true
        
        hintLabel.isHidden = true
        reloadButton.isHidden = true
    }
    
    private func requestData(requestType: RequestType) {
        switch requestType {
        case .requestCompanies(_, _):
            NetworkService.loadData(decodingType: [Company].self, token: token) { result in
                switch result {
                case .success(let array):
                    self.companiesArray = array.sorted(by: { $0.companyName < $1.companyName })
                    DispatchQueue.main.async { [weak self] in
                        self?.companyPickerView.reloadAllComponents()
                        self?.requestQuoteUpdate()
                    }
                case .failure(let error):
                    self.handleError(errorType: error)
                }
            }
        case .requestQoute(_, _, _):
            guard let symbol = symbol else { return }
            NetworkService.loadData(decodingType: Quote.self, token: token, symbol: symbol) { result in
                switch result {
                case .success(let quote):
                    DispatchQueue.main.async { [weak self] in
                        self?.displayStockInfo(data: quote)
                    }
                case .failure(let error):
                    self.handleError(errorType: error)
                }
            }
        case .requestLogo(_, _, _):
            guard let symbol = symbol else { return }
            NetworkService.loadData(decodingType: ImageData.self, token: token, symbol: symbol) { result in
                switch result {
                case .success(let logo):
                    let imageURL = URL(string: logo.url!)
                    self.logoImageView.load(url: imageURL!)
                case .failure(let error):
                    self.handleError(errorType: error)
                }
            }
        }
    }
    
    // Save error text for email and show alert
    private func handleError(errorType: ErrorType) {
        tempErrorText = errorType.rawValue
        showALert(errorType: errorType)
    }
    
    // Display parsed data on the screen
    private func displayStockInfo(data: Quote) {
        activityIndicator.stopAnimating()

        companyNameLabel.text = data.companyName
        companySymbolLabel.text = data.symbol
        priceLabel.text = "\(data.latestPrice!)"
        priceChangeLabel.text = "\(data.change!)"
        
        // Change label text color depending on "change" value
        if data.change! > 0 {
            priceChangeLabel.textColor = .systemGreen
        } else if data.change! < 0 {
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
        symbol = companiesArray[selectedRow].symbol

        DispatchQueue.global(qos: .default).async {
            self.requestData(requestType: .requestQoute(nil, nil, nil))
            self.requestData(requestType: .requestLogo(nil, nil, nil))
        }
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
        let messageText = errorType.rawValue
        
        DispatchQueue.main.async {
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: { _ in
                self.reloadButton.isHidden = false
                self.alertController = nil
            })

            // Prevent from showing multiple alert controllers
            guard self.alertController == nil else { return }

            self.alertController = AlertService.customAlert(title: "Error", message: messageText, actions: [okAction])

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
            print("error with email")
        }
    }
    
// MARK: IBActions
    
    @IBAction func reloadButtonTapped(_ sender: UIButton) {
        requestData(requestType: .requestCompanies(nil, nil))
    }
    
}

// MARK: UIPickerViewDataSource

extension ViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return companiesArray.count
    }
    
    // Customize label inside picker view
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.text = companiesArray[row].companyName
        label.sizeToFit()
        return label
    }
}

// MARK: UIPickerViewDelegate

extension ViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return companiesArray[row].companyName
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
