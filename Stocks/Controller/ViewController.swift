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
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var reloadButton: UIButton!
    @IBOutlet private weak var companyNameLabel: UILabel!
    @IBOutlet private weak var companySymbolLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var priceChangeLabel: UILabel!
    @IBOutlet private weak var logoImageView: UIImageView!
    @IBOutlet private weak var hintLabel: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView! {
        didSet { activityIndicator.hidesWhenStopped = true }
    }

    @IBOutlet weak var companyPickerView: UIPickerView! {
        didSet {
            companyPickerView.dataSource = self
            companyPickerView.delegate = self
        }
    }
    
    // MARK: - Private properties
    
    private var alertController: UIAlertController?
    private let devEmail = "support@gmail.com"

    /// Stores error text for report
    private var tempErrorText = ""

    /// Symbol for data request
    private var symbol: String?

    /// Token to access API data
    private let token = "sk_2300dc06c77a4de5a7b9b4301594f733"

    /// Companies for UIPickerView
    private var companiesArray = [Company]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        requestData(requestType: .requestCompanies(nil, nil))
    }
    
    // MARK: - Private methods
    
    private func setupView() {
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
    
    /// Save error text for email and show alert
    private func handleError(errorType: ErrorType) {
        tempErrorText = errorType.rawValue
        showALert(errorType: errorType)
    }
    
    /// Display parsed data on the screen
    private func displayStockInfo(data: Quote) {
        activityIndicator.stopAnimating()

        companyNameLabel.text = data.companyName
        companySymbolLabel.text = data.symbol
        priceLabel.text = "\(data.latestPrice!)"
        priceChangeLabel.text = "\(data.change!)"
        
        // Change label text color depending on "change" value
        if let changeValue = data.change {
            priceChangeLabel.textColor = changeValue > 0 ? .systemGreen : .systemRed
        }
    }
    
    private func requestQuoteUpdate() {
        activityIndicator.startAnimating()
        companyNameLabel.numberOfLines = 2
        logoImageView.defaultSetup()
        
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
    
    /// Update labels text and text color
    private func updateLabels() {
        let labelArray = [companyNameLabel, companySymbolLabel, priceLabel, priceChangeLabel]
        for label in labelArray {
            label?.text = "-"
            label?.textColor = UIColor { color in
                switch color.userInterfaceStyle {
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
            let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                self.reloadButton.isHidden = false
                self.alertController = nil
            }
            // Prevent from showing multiple alert controllers
            guard self.alertController == nil else { return }

            self.alertController = AlertService.customAlert(title: "Error", message: messageText, actions: [okAction])
            guard let alert = self.alertController else { return }
            self.present(alert, animated: true)
            self.activityIndicator.stopAnimating()
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func reloadButtonTapped(_ sender: UIButton) {
        requestData(requestType: .requestCompanies(nil, nil))
    }
    
}

// MARK: - UIPickerViewDataSource

extension ViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        companiesArray.count
    }
    
    // Customize label inside picker view
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.text = companiesArray[row].companyName
        label.sizeToFit()
        return label
    }
}

// MARK: - UIPickerViewDelegate

extension ViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        companiesArray[row].companyName
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        requestQuoteUpdate()
    }
}

// MARK: - MFMailComposeViewControllerDelegate

extension ViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
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
}
