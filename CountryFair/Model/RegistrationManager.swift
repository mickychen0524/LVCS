//
//  RegistrationManager.swift
//  CountryFair
//
//  Created by Mac on 10/12/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import Foundation


class RegistrationManager {
    
    static let shared: RegistrationManager = RegistrationManager()
    
    var countOfAttempt: Int = 0
    
    let tryAttemptMaxCount = 5
    
    var tryRegistrationAgain: Bool {
        return countOfAttempt < tryAttemptMaxCount
    }

}

class RegistrationFailAlert: UIAlertController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let okAction = UIAlertAction(title: "Try again", style: .default) { (action) in
            
        }
        self.addAction(okAction)
    }
    
}
