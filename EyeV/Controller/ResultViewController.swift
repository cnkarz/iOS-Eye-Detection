//
//  ResultViewController.swift
//  EyeV
//
//  Created by Cenk Arioz on 5.03.2019.
//  Copyright © 2019 Cenk Arioz. All rights reserved.
//

import UIKit

class ResultViewController: UIViewController {

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var resultLabel: UILabel!
    @IBOutlet weak var restartButton: UIButton!
    
    private let isDebugMode = false
    var labelText = ""
    var serverResponse: ServerResponse? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.isDebugMode { NSLog("DEBUG: RVC/ viewDidLoad/response: \(String(describing: self.serverResponse))") }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        resultLabel.text = labelText
        
        if self.isDebugMode { NSLog("DEBUG: RVC/ viewWillAppear/response: \(String(describing: self.serverResponse == self.serverResponse!))") }

        if serverResponse == .success {
            imageView.image = UIImage(named: "devlet_success.jpg")
        } else {
            imageView.image = UIImage(named: "devlet_fail.png")
        }
    }
    

}
