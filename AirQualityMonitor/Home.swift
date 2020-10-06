//
//  Home.swift
//  AirQualityMonitor
//
//  Created by Steven Troughton-Smith on 06/10/2020.
//

import HomeKit

class Home : NSObject, HMHomeManagerDelegate, HMAccessoryDelegate, ObservableObject {
    let homeManager = HMHomeManager()
    @Published var airQualityIndex = 0
    
    static var appKitController:NSObject?
    
    class func loadAppKitIntegrationFramework() {
        
        if let frameworksPath = Bundle.main.privateFrameworksPath {
            let bundlePath = "\(frameworksPath)/AppKitIntegration.framework"
            do {
                try Bundle(path: bundlePath)?.loadAndReturnError()
                
                let bundle = Bundle(path: bundlePath)!
                NSLog("[APPKIT BUNDLE] Loaded Successfully")
                
                if let appKitControllerClass = bundle.classNamed("AppKitIntegration.AppKitController") as? NSObject.Type {
                    appKitController = appKitControllerClass.init()
                }
            }
            catch {
                NSLog("[APPKIT BUNDLE] Error loading: \(error)")
            }
        }
    }
    
    override init() {
        Home.loadAppKitIntegrationFramework()
        
        super.init()
        
        homeManager.delegate = self
    }
    
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        
        for accessory in homeManager.primaryHome!.accessories {
            accessory.delegate = self
            
            for service in accessory.services {
                queryAirQualityService(service)
            }
        }
    }
    
    func renderAirQuality() -> UIImage {
        let quality = airQualityIndex
        let size = CGSize(width: (6 * 21) + 8, height: 21)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let symcfg = UIImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        
        let image = renderer.image { (UIGraphicsImageRendererContext) in
            for i in 0..<6 {
                
                var glyph = UIImage(systemName: "leaf", withConfiguration: symcfg)?.withRenderingMode(.alwaysTemplate).withHorizontallyFlippedOrientation()
                
                if i > 0 {
                    glyph = UIImage(systemName: "star.fill", withConfiguration: symcfg)?.withRenderingMode(.alwaysTemplate)
                }
                
                if i > quality {
                    glyph = UIImage(systemName: "star", withConfiguration: symcfg)?.withRenderingMode(.alwaysTemplate)
                }
                
                glyph?.draw(at: CGPoint(x: (i > 0 ? 8 : 0) + i * 21, y: (i == 0) ? 4 : 2))
            }
        }
        
        return image.withRenderingMode(.alwaysTemplate)
    }
    
    func queryAirQualityService(_ service : HMService) {
        if service.serviceType == HMServiceTypeAirQualitySensor {
            
            for characteristic in service.characteristics {
                
                switch characteristic.characteristicType {
                case HMCharacteristicTypeAirQuality:
                    characteristic.readValue { error in
                        
                        let number = characteristic.value as! NSNumber
                        
                        let value = HMCharacteristicValueAirQuality(rawValue: number.intValue)
                        switch value {
                        case .excellent:
                            self.airQualityIndex = 5
                        case .good:
                            self.airQualityIndex = 4
                        case .fair:
                            self.airQualityIndex = 3
                        case .inferior:
                            self.airQualityIndex = 2
                        case .poor:
                            self.airQualityIndex = 1
                        case .unknown:
                            self.airQualityIndex = 0
                        default:
                            break
                        }
                        
                        let image = self.renderAirQuality()
                        let data = image.pngData()
                        if let data = data {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AirQuality"), object: nil, userInfo: ["data" : data])
                        }
                    }
                    break
                default:
                    break
                }
                
            }
        }
    }
    
    // MARK: - Delegate Methods
    
    func homeManager(_ manager: HMHomeManager, didUpdate status: HMHomeManagerAuthorizationStatus) {
        
        switch status {
        case .authorized:
            NSLog("[HOMEKIT STATUS] Authorized")
        case .determined:
            NSLog("[HOMEKIT STATUS] Determined")
        case .restricted:
            NSLog("[HOMEKIT STATUS] Restricted")
            
        default:
            break
        }
    }
    
    func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
        queryAirQualityService(service)
    }
}
