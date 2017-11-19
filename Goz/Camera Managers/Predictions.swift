//
//  Predictions.swift
//  Goz
//
//  Created by John N Blanchard on 11/7/17.
//  Copyright © 2017 JohnNBlanchard. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

let inputWidth = 350
let inputHeight = 350

extension Camera {
  func poorPredict(using sample: CMSampleBuffer, connection: AVCaptureConnection) {
    //image size 350x350
    guard let delegate = presenter else { return }
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sample) else { return }
    CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
    guard let context = CGContext(data: CVPixelBufferGetBaseAddress(imageBuffer),
                                  width: CVPixelBufferGetWidth(imageBuffer),
                                  height: CVPixelBufferGetHeight(imageBuffer),
                                  bitsPerComponent: 8,
                                  bytesPerRow: CVPixelBufferGetBytesPerRow(imageBuffer),
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                                    | CGBitmapInfo.byteOrder32Little.rawValue),
      let quartzImage = context.makeImage() else { return }
    CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
    var frameImage = UIImage(cgImage: quartzImage, scale: 1, orientation: UIImageOrientation.up)

    switch delegate.lastOrientation() {
    case .landscapeLeft:
      frameImage = frameImage.imageRotatedBy(degrees: 0, flipX: false, flipY: true) ?? frameImage
    case .landscapeRight:
      frameImage = frameImage.imageRotatedBy(degrees: 0, flipX: true, flipY: false) ?? frameImage
    default:
      frameImage = frameImage.imageRotatedBy(degrees: 90, flipX: false, flipY: true) ?? frameImage
    }

    UIGraphicsBeginImageContextWithOptions(CGSize(width: inputWidth, height: inputHeight), false, 0.0)
    //frameImage.draw(in: CGRect(x: 0, y: 0, width: inputWidth, height: inputHeight))
    frameImage.draw(in: aspectFitFrame(destSize: CGSize(width: inputWidth, height: inputHeight), srcSize: frameImage.size))

    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()

    guard let dogFrame = scaledImage.toBuffer() else { return }

    guard Bundle(for: GozBlah.self).url(forResource: "GozBlah", withExtension:"mlmodelc") != nil else { return }
    guard let prediction = try? GozBlah().prediction(image: dogFrame) else { return }
    DispatchQueue.main.async {
      self.insight?.show(breedProb: prediction.breedProbability)
    }
  }

  /*
  func predict(using sample: CMSampleBuffer) {
    // image size 224x224

    var bufferRef: CVPixelBuffer?

    guard let imageBuffer = CMSampleBufferGetImageBuffer(sample) else { return }
    CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
    guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else { return }
    let pixelFormat = CVPixelBufferGetPixelFormatType(imageBuffer)
    let height = UInt(CVPixelBufferGetHeight(imageBuffer))
    let width = UInt(CVPixelBufferGetWidth(imageBuffer))
    let rowPerBytes = CVPixelBufferGetBytesPerRow(imageBuffer)

    guard let destData = malloc(4*224*224) else { return }

    defer {
      free(destData)
      CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
      CVPixelBufferUnlockBaseAddress(bufferRef!, CVPixelBufferLockFlags(rawValue: 0))
    }

    var srcBuffer = vImage_Buffer(data: baseAddress, height: height, width: width, rowBytes: rowPerBytes)
    var destBuffer = vImage_Buffer(data: destData, height: 224, width: 224, rowBytes: 224*4)

    let err = vImageScale_ARGB8888(&srcBuffer, &destBuffer, nil, 0)
    guard err == kvImageNoError else {
      debugPrint(err)
      return
    }

    let result = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, 224, 224, pixelFormat, &destBuffer, 224 * 4, nil, nil, nil, &bufferRef)
    CVPixelBufferLockBaseAddress(bufferRef!, CVPixelBufferLockFlags(rawValue: 0))

    guard result == kCVReturnSuccess else {
      debugPrint(result)
      return
    }

    guard let dogBuf = bufferRef else { return }
    let _ = UIImage(ciImage: CIImage(cvPixelBuffer: dogBuf))
    DispatchQueue.main.async {
//      self.predictionImageView.image = dogImg
//      self.predictionImageView.backgroundColor = UIColor.yellow
    }

    //guard let _ = try? self.model.prediction(data: dogBuf) else { return }
    DispatchQueue.main.async {
//      self.predictionLabel.text = prediction.classLabel
    }
  }
 */

  func aspectFitFrame(destSize:CGSize, srcSize:CGSize) -> CGRect{
    let hfactor : CGFloat = srcSize.width/destSize.width
    let vfactor : CGFloat = srcSize.height/destSize.height

    let factor : CGFloat = max(hfactor, vfactor)

    let newWidth : CGFloat = srcSize.width / factor
    let newHeight : CGFloat = srcSize.height / factor

    var x:CGFloat = 0.0
    var y:CGFloat = 0.0
    if newWidth > newHeight{
      y = (destSize.height - newHeight)/2
    }
    if newHeight > newWidth {
      x = (destSize.width - newWidth)/2
    }
    return CGRect(x: x, y: y, width: newWidth, height: newHeight)
  }
}
