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
  func poorPredict(using sample: CMSampleBuffer, connection: AVCaptureConnection) {
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
    var frameImage = UIImage(cgImage: quartzImage, scale: 1, orientation: UIImageOrientation.up)

    switch lastOrientation {
    case .landscapeLeft:
      debugPrint("ll")
      frameImage = frameImage.imageRotatedBy(degrees: 0, flipX: false, flipY: true) ?? frameImage
    case .landscapeRight:
      debugPrint("lr")
      frameImage = frameImage.imageRotatedBy(degrees: 0, flipX: true, flipY: false) ?? frameImage
    default:
      debugPrint("def")
      frameImage = frameImage.imageRotatedBy(degrees: 90, flipX: false, flipY: true) ?? frameImage
    }

    UIGraphicsBeginImageContextWithOptions(CGSize(width: 300, height: 400), false, 0.0)
    frameImage.draw(in: aspectFitFrame(destSize: CGSize(width: 300, height: 400), srcSize: frameImage.size))

    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()

    guard let dogFrame = scaledImage.toBuffer() else { return }

    guard let prediction = try? self.model.prediction(data: dogFrame) else { return }
    DispatchQueue.main.async {
      self.insightController?.predictions = prediction.breedProbability
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
//      self.predictionImageView.image = dogImg
//      self.predictionImageView.backgroundColor = UIColor.yellow
    }

    guard let prediction = try? self.model.prediction(data: dogBuf) else { return }
    DispatchQueue.main.async {
//      self.predictionLabel.text = prediction.classLabel
      //print(prediction.breedProbability)
    }
  }

  func aspectFitFrame(destSize:CGSize, srcSize:CGSize) -> CGRect{
    let imageSize:CGSize  = srcSize
    let viewSize:CGSize = destSize

    let hfactor : CGFloat = imageSize.width/viewSize.width
    let vfactor : CGFloat = imageSize.height/viewSize.height

    let factor : CGFloat = max(hfactor, vfactor)

    let newWidth : CGFloat = imageSize.width / factor
    let newHeight : CGFloat = imageSize.height / factor

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

extension ViewController: Insights {
  struct prediction { var name = ""; var confidence = 0.0 }

  func consensus(on place: Int) -> (String, Double)? {
    guard place < predictions.count else {
      debugPrint("Attempting to create consensus on out of bounds placement.")
      return nil
    }
    let predictionMap = predictions.map { (entry) -> prediction in
      let data = entry[place]
      return prediction(name: data.0, confidence: data.1)
    }
    var count: [String: Int] = [:]
    for data in predictionMap {
      count[data.name] = (count[data.name] ?? 0) + 1
    }
    guard let consensusEntry = count.first(where: { (entry) -> Bool in
      return entry.value == count.values.max()
    }) else { return nil }
    var bestValue = 0.0
    for aPrediction in predictionMap {
      guard aPrediction.name == consensusEntry.key else { continue }
      guard aPrediction.confidence > bestValue else { continue }
      bestValue = aPrediction.confidence
    }
    return (consensusEntry.key, bestValue)
  }

  func curatePrediction() {
    predictionPlacement.removeAll()
    for i in 0..<3 { predictionPlacement.append(consensus(on: i)) }
    performSegue(withIdentifier: "inference", sender: self)
    predictionIndicator.stopAnimating()
  }


  func topPredictionsFromFrame(entry: [(String, Double)]) {
    guard predictionIndicator.tag == 14 else { return }
    guard predictions.count < 7 else {
      predictionIndicator.tag = 2
      //curatePrediction()
      return
    }
    predictions.append(entry)
  }
}


