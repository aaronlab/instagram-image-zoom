//
//  ImageManager.swift
//  TableViewCellZoom
//
//  Created by Aaron Lee on 2021/11/13.
//

import UIKit

final class ImageManager {
    
    static let shared = ImageManager()
    
    private init() { }
    
    private let utilityQueue = DispatchQueue(label: "net.aaronlab.ImageManager.utility",
                                             qos: .utility,
                                             attributes: .concurrent)
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
}
