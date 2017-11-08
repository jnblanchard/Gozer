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
import Accelerate

extension ViewController {
  func poorPredict(using sample: CMSampleBuffer) {
    //image size 400x300
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
    let frameImage = UIImage(cgImage: quartzImage, scale: 1, orientation: UIImageOrientation.up)
    UIGraphicsBeginImageContextWithOptions(CGSize(width: 400, height: 300), false, 0.0)
    frameImage.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: 400, height: 300)))

    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()

    let rotatedImg = scaledImage.imageRotatedBy(degrees: 90, flipX: false, flipY: true)

    DispatchQueue.main.async {
      self.predictionImageView.image = rotatedImg
    }

    guard let dogFrame = rotatedImg?.toBuffer() else { return }

    guard let prediction = try? self.model.prediction(data: dogFrame) else { return }
    DispatchQueue.main.async {
      self.predictionLabel.text = prediction.classLabel
      //print(prediction.breedProbability)
    }
  }

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
      print(err)
      return
    }

    let result = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, 224, 224, pixelFormat, &destBuffer, 224 * 4, nil, nil, nil, &bufferRef)
    CVPixelBufferLockBaseAddress(bufferRef!, CVPixelBufferLockFlags(rawValue: 0))

    guard result == kCVReturnSuccess else {
      print(result)
      return
    }

    guard let dogBuf = bufferRef else { return }
    let dogImg = UIImage(ciImage: CIImage(cvPixelBuffer: dogBuf))
    DispatchQueue.main.async {
      self.predictionImageView.image = dogImg
      self.predictionImageView.backgroundColor = UIColor.yellow
    }

    guard let prediction = try? self.model.prediction(data: dogBuf) else { return }
    DispatchQueue.main.async {
      self.predictionLabel.text = prediction.classLabel
      //print(prediction.breedProbability)
    }
  }
}


