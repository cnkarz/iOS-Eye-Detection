//
//  LoginViewController.swift
//  EyeV
//
//  Created by Cenk Arioz on 28.01.2019.
//  Copyright © 2019 Cenk Arioz. All rights reserved.
//

import UIKit

class IndexViewController: UIViewController, UITextFieldDelegate {

    private var isDebugMode = false
    
    @IBOutlet weak var tcknTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "EyeV"
        tcknTextField.delegate = self
        tcknTextField.keyboardType = .numberPad
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if isDebugMode { NSLog("DEBUG: IndexViewController / prepare") }
        
//        if isTcknValid(text: tcknTextField.text?) {
        guard let tckn = tcknTextField.text else {
            displayAlert()
            return
            
        }
        if tckn.count != 11 {
            displayAlert()
            
        } else {
            guard let authenticationVC = segue.destination as? AuthenticationViewController else {
                return
            }
            authenticationVC.userTCKN = tckn
            if segue.identifier == "logIn" {
                authenticationVC.viewMode = .logIn
            } else if segue.identifier == "signUp" {
                authenticationVC.viewMode = .signUp
            }
        }
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.borderWidth = 1
        textField.text = ""
        loginButton.isUserInteractionEnabled = true
        signUpButton.isUserInteractionEnabled = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    private func displayAlert() {
        loginButton.isUserInteractionEnabled = false
        signUpButton.isUserInteractionEnabled = false
        
        tcknTextField.layer.borderColor = UIColor.red.cgColor
        tcknTextField.layer.borderWidth = 2
        
        let alertMessage = "Lütfen 11 haneli TC kimlik numaranızı giriniz."
        let alertController = UIAlertController(title: nil, message: alertMessage, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
        
    }

}

