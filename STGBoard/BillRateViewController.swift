//
//  BillRateViewController.swift
//  STGBoard
//
//  Created by Ryan Plitt on 9/25/17.
//  Copyright © 2017 Ryan Plitt. All rights reserved.
//

import UIKit
import TextFieldEffects
import ChameleonFramework

class BillRateViewController: UIViewController, UITextFieldDelegate {
    
    static let dismissNotificationName = Notification.Name("dismiss")
    @IBOutlet weak var salarySegmentedControl: UISegmentedControl!
    @IBOutlet weak var wageTextField: MadokaTextField!
    @IBOutlet weak var containerView: UIView!
    
    weak var delegate: BillRateViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateWageTextFieldPlaceholderText()
        wageTextField.keyboardType = .numberPad
        wageTextField.delegate = self
        addAccessoryViewToTextfield()
        wageTextField.addTarget(self, action: #selector(myTextFieldDidChange), for: .editingChanged)
        
        NotificationCenter.default.addObserver(forName: BillRateViewController.dismissNotificationName, object: nil, queue: OperationQueue.main) { (_) in
            self.wageTextField.resignFirstResponder()
        }
    
        wageTextField.placeholderColor = FlatTealDark().withAlphaComponent(0.4)
        wageTextField.borderColor = FlatTealDark()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func addAccessoryViewToTextfield() {
        let toolbar:UIToolbar = UIToolbar()
        //create left side empty space so that done button set on right side
        let clearButton = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearButtonAction))
        let flexSpace = UIBarButtonItem(barButtonSystemItem:    .flexibleSpace, target: nil, action: nil)
        let doneBtn: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction))
        toolbar.setItems([clearButton, flexSpace, doneBtn], animated: false)
        toolbar.sizeToFit()
        self.wageTextField.inputAccessoryView = toolbar
    }
    
    @IBAction func salaryHourlySegmentedControllerChangeValue(_ sender: UISegmentedControl) {
        wageTextField.text = ""
        updateWageTextFieldPlaceholderText()
        textFieldDidEndEditing(wageTextField)
    }
    
    private func updateWageTextFieldPlaceholderText() {
        
        // updates the placeholder if necessary.
        
        var placeholderString = String()
        switch (self.salarySegmentedControl.selectedSegmentIndex, self.wageTextField.text!.isEmpty, self.wageTextField.isEditing) {
        case (0, true, false):
            placeholderString = "Enter Salary Here"
        case (1, true, false):
            placeholderString = "Enter Hourly Wage Here"
        case (0, false, true), (0, false, false), (0, true, true):
            placeholderString = "Salary"
        case (1, false, true), (1, false, false),(1, true, true):
            placeholderString = "Hourly"
        default:
            break
        }
        
        if wageTextField.placeholder != placeholderString {
            wageTextField.placeholder = placeholderString
        }
    }
    
    @objc private func doneButtonAction() {
        wageTextField.resignFirstResponder()
        updateWageTextFieldPlaceholderText()
    }
    
    @objc private func clearButtonAction() {
        wageTextField.text = ""
        updateWageTextFieldPlaceholderText()
    }
    
    func myTextFieldDidChange(_ textField: UITextField) {
        switch salarySegmentedControl.selectedSegmentIndex {
        case 0:
            if let amountString = textField.text?.currencyInputFormattingForSalary() {
                textField.text = amountString
                guard var wageAmount = textField.text, wageAmount.characters.count > 0 else {
                    self.delegate?.updateFields(withWageType: salarySegmentedControl.selectedSegmentIndex == 0 ? .salary : .hourly, andWage: 0.00)
                    return
                }
                
                self.delegate?.updateFields(withWageType: salarySegmentedControl.selectedSegmentIndex == 0 ? .salary : .hourly, andWage: wageAmount.currencyDouble())
            }
        case 1:
            if let amountString = textField.text?.currencyInputFormattingForHourly() {
                textField.text = amountString
                guard var wageAmount = textField.text, wageAmount.characters.count > 0 else {
                    self.delegate?.updateFields(withWageType: salarySegmentedControl.selectedSegmentIndex == 0 ? .salary : .hourly, andWage: 0.00)
                    return
                }
                
                self.delegate?.updateFields(withWageType: salarySegmentedControl.selectedSegmentIndex == 0 ? .salary : .hourly, andWage: wageAmount.currencyDouble())
            }
        default: return
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let billRateCalcTVC = segue.destination as? BillRateCalculatorTableViewController {
            self.delegate = billRateCalcTVC
            billRateCalcTVC.frameOfView = containerView.frame.height
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard let textField = textField as? MadokaTextField else { return }
        updateWageTextFieldPlaceholderText()
        textField.placeholderColor = FlatTealDark().withAlphaComponent(1.0)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text == "" {
            guard let textField = textField as? MadokaTextField else { return }
            updateWageTextFieldPlaceholderText()
            textField.placeholderColor = FlatTealDark().withAlphaComponent(0.4)
            self.delegate?.updateFields(withWageType: .salary, andWage: 0.00)
        }
    }
    
}

enum WageType {
    case hourly
    case salary
}

extension String {
    
    // formatting text for currency textField
    func currencyInputFormattingForSalary() -> String {
        
        var number: NSNumber!
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.generatesDecimalNumbers = false
        formatter.maximumFractionDigits = 0
        formatter.currencySymbol = "$"
        
        var amountWithPrefix = self
        
        // remove from String: "$", ".", ","
        let regex = try! NSRegularExpression(pattern: "[^0-9]", options: .caseInsensitive)
        amountWithPrefix = regex.stringByReplacingMatches(in: amountWithPrefix, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.characters.count), withTemplate: "")
        
        let double = (amountWithPrefix as NSString).doubleValue
        number = NSNumber(value: (double))
        
        // if first number is 0 or all numbers were deleted
        guard number != 0 as NSNumber else {
            return ""
        }
        
        return formatter.string(from: number)!
    }
    
    func currencyInputFormattingForHourly() -> String {
        
        var number: NSNumber!
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.currencySymbol = "$"
        
        var amountWithPrefix = self
        
        // remove from String: "$", ".", ","
        let regex = try! NSRegularExpression(pattern: "[^0-9]", options: .caseInsensitive)
        amountWithPrefix = regex.stringByReplacingMatches(in: amountWithPrefix, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.characters.count), withTemplate: "")
        
        let double = (amountWithPrefix as NSString).doubleValue
        number = NSNumber(value: (double) / 100)
        
        // if first number is 0 or all numbers were deleted
        guard number != 0 as NSNumber else {
            return ""
        }
        
        return formatter.string(from: number)!
    }
    
    func currencyDouble() -> Double {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        
        
        return formatter.number(from: self)!.doubleValue
    }
}

protocol BillRateViewControllerDelegate: class {
    func updateFields(withWageType wageType: WageType, andWage wage: Double)
}
