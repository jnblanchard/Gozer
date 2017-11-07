//
//  UIImageExtensions.swift
//  Goz
//
//  Created by John N Blanchard on 11/7/17.
//  Copyright © 2017 JohnNBlanchard. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {

  func toBuffer() -> CVPixelBuffer? {
    let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
    var pixelBuffer : CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
    guard (status == kCVReturnSuccess) else { return nil }

    CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: pixelData, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

    context?.translateBy(x: 0, y: size.height)
    context?.scaleBy(x: 1.0, y: -1.0)

    UIGraphicsPushContext(context!)
    draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    UIGraphicsPopContext()
    CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

    return pixelBuffer
  }

  func imageRotatedBy(degrees: CGFloat, flipX: Bool, flipY: Bool = true) -> UIImage? {
    let degreesToRadians: (CGFloat) -> CGFloat = {
      return $0 / 180.0 * .pi
    }

    let rotatedSize = CGRect(origin: CGPoint.zero, size: size).applying(CGAffineTransform(rotationAngle: degreesToRadians(degrees))).size

    UIGraphicsBeginImageContext(rotatedSize)
    guard let bitmap = UIGraphicsGetCurrentContext() else { return nil }

    bitmap.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0)

    bitmap.rotate(by: degreesToRadians(degrees))

    let x = flipX ? CGFloat(-1.0) : CGFloat(1.0)
    let y = flipY ? CGFloat(-1.0) : CGFloat(1.0)
    bitmap.scaleBy(x: x, y: y)

    bitmap.draw(cgImage!, in: CGRect(x: -size.width / 2,
                                     y: -size.height / 2,
                                     width: size.width,
                                     height: size.height))

    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage
  }
}
