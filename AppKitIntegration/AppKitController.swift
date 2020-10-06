//
//  AppKitController.swift
//  AppKitIntegration
//
//  Created by Steven Troughton-Smith on 29/09/2020.
//

import AppKit

extension NSWindow {
    @objc func AirQuality_makeKeyAndOrderFront(_ sender: Any) {
        NSLog("[NSWindow] No window for you!")
    }
}

@objc class AppKitController: NSObject {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    override init() {
        super.init()
        
        let m1 = class_getInstanceMethod(NSClassFromString("NSWindow"), NSSelectorFromString("makeKeyAndOrderFront:"))
        let m2 = class_getInstanceMethod(NSClassFromString("NSWindow"), NSSelectorFromString("AirQuality_makeKeyAndOrderFront:"))
        
        if let m1 = m1, let m2 = m2 {
            NSLog("Swizzling NSWindow")
            method_exchangeImplementations(m1, m2)
        }

        NSLog("[AppKitController] Loaded successfully")
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "AirQuality"), object: nil, queue: nil) { note in
            if let userInfo = note.userInfo {
                let data = userInfo["data"] as! Data
                self.setupMenuItem(imageData: data)
            }
        }
    }
    
    func setupMenuItem(imageData:Data?) {
        if let data = imageData {
            NSLog("[MENU ITEM] Received image data")
            let image = NSImage(data: data)
            image?.isTemplate = true
            statusItem.image = image
            statusItem.menu = createMenu()
        }
        
    }
    
    func createMenu() -> NSMenu {
        let menu = NSMenu()
        let menuItem = menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "")
        menuItem.target = self
        
        return menu
    }
    
    @objc func quit(_ sender:Any?) {
        exit(0)
    }
}
