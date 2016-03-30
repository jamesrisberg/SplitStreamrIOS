//
//  LoginViewController.swift
//  SplitStreamr
//
//  Created by James on 3/29/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var usernameView: UIView!
    @IBOutlet weak var passwordView: UIView!
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    var restAccessor = RestNetworkAccessor();
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleViews()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let username = UICKeyChainStore.stringForKey("com.currentuser.username", service: "com.splitstreamr") {
            usernameField.text = username
            
            if let password = UICKeyChainStore.stringForKey("com.currentuser.password", service: "com.splitstreamr") {
                passwordField.text = password
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func styleViews() {
        styleViewWithShadow(signInButton)
    }
    
    func styleViewWithShadow(view: UIView) {
        view.layer.shadowColor = UIColor.blackColor().CGColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSizeMake(0.0, 1.0)
        view.layer.shadowRadius = 1.0
        view.layer.cornerRadius = 4.0
    }
    
    func fadeInFieldBar(bar: UIView) {
        UIView.animateWithDuration(0.3) {
            bar.backgroundColor = blue1
        }
    }
    
    func fadeOutFieldBar(bar: UIView) {
        UIView.animateWithDuration(0.3) {
            bar.backgroundColor = offWhiteColor
        }
    }
    
    @IBAction func signIn() {
        errorLabel.hidden = true
        let (valid, message) = validLoginForm()
        
        if valid {
            restAccessor.signInUser(usernameField.text!, password: passwordField.text!) { (error, user) in
                if let e = error {
                    self.displayError(e.localizedDescription)
                } else if let data = user {
                    User.sharedInstance.configureWithUserData(data)
                    
                    UICKeyChainStore.setString(self.usernameField.text, forKey: "com.currentuser.username", service: "com.emojr")
                    UICKeyChainStore.setString(self.passwordField.text, forKey: "com.currentuser.password", service: "com.emojr")
                    
                    self.performSegueWithIdentifier("login", sender: self)
                }
            }
        } else {
            displayError(message)
        }
    }
    
    @IBAction func signUp() {
        
    }
    
    func displayError(message: String) {
        errorLabel.text = message
        errorLabel.hidden = false
    }
    
    func validLoginForm() -> (Bool, String) {
        if let username = usernameField.text {
            if let password = passwordField.text {
                if (username == "" || password == "") {
                    return (false, "Please fill out both fields!")
                }
            } else {
                return (false, "Please fill out both fields!")
            }
        } else {
            return (false, "Please fill out both fields!")
        }
        
        return (true, "Success")
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(textField: UITextField) {
        if textField.isEqual(usernameField) {
            fadeInFieldBar(usernameView)
        } else {
            fadeInFieldBar(passwordView)
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField.isEqual(usernameField) {
            fadeOutFieldBar(usernameView)
        } else {
            fadeOutFieldBar(passwordView)
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
}
