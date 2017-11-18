//
//  CameraExtensions.swift
//  Goz
//
//  Created by John N Blanchard on 11/7/17.
//  Copyright © 2017 JohnNBlanchard. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

protocol CameraPresenter {
  func lastOrientation() -> UIDeviceOrientation
  func present(session: AVCaptureSession)
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    guard let imageBuffer = photo.pixelBuffer else { return }
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

    guard let connection = output.connection(with: .video) else { return }
    if connection.videoOrientation == .landscapeLeft {
      frameImage = frameImage.imageRotatedBy(degrees: 0, flipX: true, flipY: false) ?? frameImage
    } else if connection.videoOrientation == .portrait {
      frameImage = frameImage.imageRotatedBy(degrees: 90, flipX: false, flipY: true) ?? frameImage
    } else if connection.videoOrientation == .landscapeLeft {
      frameImage = frameImage.imageRotatedBy(degrees: 90, flipX: false, flipY: false) ?? frameImage
    }

    UIGraphicsBeginImageContextWithOptions(CGSize(width: inputWidth, height: inputHeight), false, 0.0)
    frameImage.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: inputWidth, height: inputHeight)))

    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()

    guard let scaledBuffer = scaledImage.toBuffer() else { return }
    do {
      let prediction = try Gozz().prediction(image: scaledBuffer)
      predictionPlacement = orderedFirstNInferences(n: numInferences, dict: prediction.breedProbability)
      predictionImage = frameImage
      DispatchQueue.main.async { self.performSegue(withIdentifier: "inference", sender: self) }
    } catch {
      debugPrint(error)
    }
  }
}
