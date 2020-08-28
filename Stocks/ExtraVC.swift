//
//  MainVC.swift
//  Stocks
//
//  Created by Олег Еременко on 28.08.2020.
//  Copyright © 2020 Oleg Eremenko. All rights reserved.
//

import UIKit

class ExtraVC: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var logoImageView: UIImageView!
    
    private var companyDictData: [String : Any] = [:]
    private let defaultCellLabels = ["Company name", "Symbol", "Price", "Price change"]
    
    private lazy var companies = [
        "Apple": "AAPL",
        "Microsoft": "MSFT",
        "Google": "GOOG",
        "Amazon": "AMZN",
        "Facebook": "FB"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupPickerView()
        
        activityIndicator.hidesWhenStopped = true
        
        requestQuoteUpdate()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
//        tableView.isUserInteractionEnabled = false
    }
    
    private func setupPickerView() {
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
    }
    
    private func requestQuoteUpdate() {
        activityIndicator.startAnimating()
        
        logoImageView.image = UIImage(named: "brand")
        logoImageView.contentMode = .scaleAspectFit
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(companies.values)[selectedRow]
        requestQuote(for: selectedSymbol)
    }
    
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
            
            guard let json = jsonObject as? [String: Any] else { return print("Invalid JSON") }
            companyDictData = json
            
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
                self?.activityIndicator.stopAnimating()
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

}

extension ExtraVC: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(50)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell1") as! TableViewCell1
        cell.label1.text = defaultCellLabels[indexPath.row]
        switch indexPath.row {
        case 0: cell.label2.text = companyDictData["companyName"] as? String
        case 1: cell.label2.text = companyDictData["symbol"] as? String
        case 2:
            guard let latestPrice = companyDictData["latestPrice"] as? Double else { return cell }
            cell.label2.text = "\(latestPrice)"
        case 3:
            guard let change = companyDictData["change"] as? Double else { return cell }
            cell.label2.text = "\(change)"
        default:
            return cell
        }
        
        return cell
    }
}

extension ExtraVC: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//    }
}

extension ExtraVC: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        companies.keys.count
    }
    
    
}

extension ExtraVC: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(companies.keys)[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        requestQuoteUpdate()
    }
}
