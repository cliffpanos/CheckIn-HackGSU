//
//  Extensions.swift
//  CheckIn
//
//  Created by Cliff Panos on 4/24/17.
//  Copyright © 2017 Clifford Panos. All rights reserved.
//

import UIKit

extension UIColor {
    
    static func color(fromHex rgbValue: UInt32) ->UIColor {
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/255.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/255.0
        let blue = CGFloat(rgbValue & 0xFF)/255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}


extension UIScreen {
    
    //TODO deal with brightness

}


extension UIImage {
    
    func drawInRectAspectFill(rect: CGRect) -> UIImage {
        let targetSize = rect.size

        let widthRatio = targetSize.width  / self.size.width
        let heightRatio = targetSize.height / self.size.height
        let scalingFactor = max(widthRatio, heightRatio)
        let newSize = CGSize(width: self.size.width * scalingFactor, height: self.size.height * scalingFactor)
        
        print("Target: \(targetSize)")
        UIGraphicsBeginImageContext(targetSize)
        let origin = CGPoint(x: (targetSize.width  - newSize.width)  / 2, y: (targetSize.height - newSize.height) / 2)
        self.draw(in: CGRect(origin: origin, size: newSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        scaledImage?.draw(in: rect)
        
        return scaledImage!
    }

}




public extension UIWindow {
    
    public class presented {
        static var viewController: UIViewController!

    }
    public static func getVisibleViewControllerFrom(_ vc: UIViewController?) -> UIViewController? {
        if let nc = vc as? UINavigationController {
            return UIWindow.getVisibleViewControllerFrom(nc.visibleViewController)
        } else if let tc = vc as? UITabBarController {
            return UIWindow.getVisibleViewControllerFrom(tc.selectedViewController)
        } else {
            if let pvc = vc?.presentedViewController {
                return UIWindow.getVisibleViewControllerFrom(pvc)
            } else {
                return vc
            }
        }
    }
}