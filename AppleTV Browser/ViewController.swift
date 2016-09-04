//
//  ViewController.swift
//  AppleTV Browser
//
//  Created by Вадим Коппе on 02.09.16.
//  Copyright © 2016 Вадим Коппе. All rights reserved.
//

import UIKit
import Foundation
import GameController

class ViewController: UIViewController {
    
    private var cursorMode = false
    
    private var cursorView: UIView!
    private var temporaryURL: String!
    
    private var webView: UIWebView!
    private var link: CADisplayLink!
    private var controller: GCController!
    
    private var input: Input!
    
    private struct Input {
        var x: CGFloat
        var y: CGFloat
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        input = Input(x: 0, y: 0)
        
        cursorView = UIView.init(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
        cursorView.center = view.center
        cursorView.backgroundColor = UIColor(patternImage: UIImage(named: "Cursor")!)
        cursorView.isHidden = true
        
        webView = UIWebView.init(frame: view.bounds)
        webView.loadRequest(NSURLRequest(url: NSURL(string: "https://apple.com")! as URL) as URLRequest)
        
        view.addSubview(webView)
        view.addSubview(cursorView)
        
        link = CADisplayLink(target: self, selector: #selector(ViewController.updateCursor))
        link.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
        
        webView.scrollView.bounces = true
        webView.scrollView.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouchType.indirect.rawValue)] ;
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.setupController), name: NSNotification.Name.GCControllerDidConnect, object: nil)
    }
    
    private func toggleMode() {
        cursorMode = !cursorMode
        
        webView.scrollView.isScrollEnabled = !cursorMode
        webView.isUserInteractionEnabled = !cursorMode
        cursorView.isHidden = !cursorMode
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.first?.type == UIPressType.menu {
            if self.presentedViewController != nil {
                self.dismiss(animated: true, completion: nil)
            }else {
                webView.goBack()
            }
        }else if presses.first?.type == UIPressType.select {
            let point = webView.convert(cursorView.frame.origin, to: nil)
            webView.stringByEvaluatingJavaScript(from: NSString.localizedStringWithFormat("document.elementFromPoint(%i, %i).click()", point.x, point.y) as String)
        }else if presses.first?.type == UIPressType.playPause {
            let alertController = UIAlertController.init(title: "Enter Address", message: "", preferredStyle: UIAlertControllerStyle.alert)
            
            alertController.addTextField{ (textField) in
                textField.keyboardType = UIKeyboardType.URL;
                textField.placeholder = "Input URL"
                textField.addTarget(self, action: #selector(ViewController.alertTextFieldDidChange), for: UIControlEvents.editingChanged)
            }
            
            let okAction = UIAlertAction.init(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
                self.webView.loadRequest(NSURLRequest(url: NSURL(string: NSString(format:"https://%@", self.temporaryURL) as String) as! URL) as URLRequest)
                self.temporaryURL = nil
            })
            
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true, completion: nil)
        }else if presses.first?.type == UIPressType.upArrow {
            toggleMode()
        }
    }
    
     internal func alertTextFieldDidChange(sender: UITextField) {
        let alertController = self.presentedViewController as! UIAlertController
        let urlField = alertController.textFields?.first
        temporaryURL = urlField?.text
    }
    
    //MARK: Cursor
    
    internal func setupController() {
        
        controller = GCController.controllers().first
        
        controller.microGamepad?.dpad.valueChangedHandler = { dpad, x, y in
            self.input.x = CGFloat(x)
            self.input.y = CGFloat(-y)
        }
    }
    
    internal func updateCursor() {
        let delta: CGFloat = 5.0
        var position = cursorView.layer.position
        
        if !cursorMode {
            return
        }
        
        if input.x > 0 {
            position.x += pow(2, delta * fabs(input.x))
        }else if input.x < 0 {
            position.x -= pow(2, delta * fabs(input.x))
        }
        
        if input.y > 0 {
            position.y += pow(2, delta * fabs(input.y))
        }else if input.y < 0 {
            position.y -= pow(2, delta * fabs(input.y))
        }
        
        if position.x > view.bounds.width - cursorView.bounds.width {
            position.x = view.bounds.width - cursorView.bounds.width
        }
        
        if position.x < cursorView.bounds.width {
            position.x = cursorView.bounds.width
        }
        
        if position.y > view.bounds.height - cursorView.bounds.height {
            position.y = view.bounds.height - cursorView.bounds.height
        }
        
        if position.y < cursorView.bounds.height {
            position.y = cursorView.bounds.height
        }
        
        cursorView.layer.position = CGPoint.init(x: position.x, y: position.y)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

 
