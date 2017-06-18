//
//  LoginViewController.swift
//  True Pass
//
//  Created by Cliff Panos on 4/1/17.
//  Copyright © 2017 Clifford Panos. All rights reserved.
//

import UIKit
import QRCodeReader

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var primaryView: UIView!
    @IBOutlet weak var loginTitle: UILabel!
    
    var textFieldSelected: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        for textField in [emailTextField, passwordTextField] {
            let numberToolbar: UIToolbar = UIToolbar()
            numberToolbar.barStyle = UIBarStyle.default
            
            numberToolbar.items = [
                
                UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil),
                UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(dismissKeyboard))
            ]
            
            numberToolbar.sizeToFit()
            
            textField?.inputAccessoryView = numberToolbar
            
            textField?.isUserInteractionEnabled = true
        }
        
        let _: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView

    }

    func keyboardWillShow(notification: NSNotification) {
        
        guard !textFieldSelected else { return }
        
        print("moving up")
        
        UIView.animate(withDuration: 0.75, delay: 0.05, usingSpringWithDamping: 0.7, initialSpringVelocity: 3, options: .curveEaseIn, animations: {
        
            self.primaryView.frame.origin.y -= 75
            
        })
        self.textFieldSelected = true

        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if !self.textFieldSelected {
            return
        }
        print("moving down")
        
        UIView.animate(withDuration: 0.75, delay: 0.05, usingSpringWithDamping: 0.7, initialSpringVelocity: 3, options: .curveEaseIn, animations: {
            
            self.primaryView.frame.origin.y += 75

        }, completion: nil)
        self.textFieldSelected = false
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch (textField) {
        case emailTextField: passwordTextField.becomeFirstResponder()
        default:
            dismissKeyboard()
            signInPressed(self)
        }
        return true
    }
    
    
    //------------------------------------------
    @IBAction func signInPressed(_ sender: Any) {
        
        if (passwordMatchesEmail()) {
            animateOff()
        } else if (isAdministratorLogin()){
            let reader = QRCodeReaderViewController()
            reader.resultCallback = {
                print($1)
            }
            
            reader.cancelCallback = {
                $0.dismiss(animated: true, completion: nil)
            }
            self.present(reader, animated: true, completion: nil)
        } else {
            //Let the user know that the entered information was incorrect
            shake()
        }
    }
    //------------------------------------------
    
    
    @IBAction func emailFieldPressed(_ sender: Any) {
        print("becoming")
        passwordTextField.resignFirstResponder()
        emailTextField.becomeFirstResponder()
    }
    
    @IBAction func newAccountPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Create Account Online", message: "Create a new account at checkin.com", preferredStyle: .alert)
        let alertaction = UIAlertAction(title: "Great", style: .default, handler: nil)
        alert.addAction(alertaction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func passwordMatchesEmail() -> Bool {
        
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        
        return email == "user" && password == "pass"

    }
    
    func isAdministratorLogin() -> Bool {
        return (emailTextField.text ?? "") == "admin" && (passwordTextField.text ?? "") == "pass"
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: self)
    }
    
    
    //MARK: - Animations:
    
    func shake() {
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.repeatCount = 3
        animation.duration = 0.07
        animation.autoreverses = true
        animation.byValue = 7 //how much it moves
        self.passwordTextField.layer.add(animation, forKey: "position")
        self.emailTextField.layer.add(animation, forKey: "position")
    }
    
    func animateOff() {
        
        dismissKeyboard()
        UIView.animate(withDuration: 0.75, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 2.25, options: .curveEaseIn, animations: {
            
            let translationY = 0.5 * self.view.frame.height + 100
            self.primaryView.frame.origin.y += translationY
            self.loginTitle.text = "Login Successful!"

            
        }, completion: {_ in
            self.textFieldSelected = false
                
            C.userIsLoggedIn = true

            self.dismiss(animated: true, completion: {
                self.emailTextField.text = ""
                self.passwordTextField.text = ""

                C.userIsLoggedIn = true

            })
            C.appDelegate.tabBarController.selectedIndex = 0
            
        })
        
    }
    

    

}