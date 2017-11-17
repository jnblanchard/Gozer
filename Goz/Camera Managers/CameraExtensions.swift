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

protocol InsightPresenter {
  func show(breedProb: [String : Double]?)
}

extension Camera {

  func begin() {
    guard !captureSession.isRunning else { return }
    deviceQueue.async {
      self.captureSession.startRunning()
    }
  }

  func startSession() {
    captureSession.beginConfiguration()

    if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
      for input in inputs {
        captureSession.removeInput(input)
      }
    }

    output.setSampleBufferDelegate(self, queue: videoBufferQueue)
    output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    if captureSession.canAddOutput(output) {
      captureSession.addOutput(output)
    }

    guard let input = backInput else {
      configure()
      startSession()
      return
    }
    if captureSession.canAddInput(input) {
      captureSession.addInput(input)
    }

    if captureSession.canAddOutput(photoOutput) {
      photoOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])], completionHandler: { (finished, anError) in
        guard let error = anError else { return }
        debugPrint("Failed to set photo settings with: \(error.localizedDescription)")
      })
      captureSession.addOutput(photoOutput)
    }

    captureSession.commitConfiguration()

    presenter?.present(session: captureSession)
  }

  func stopSession() {
    deviceQueue.async {
      guard self.captureSession.isRunning else { return }
      self.captureSession.stopRunning()
    }
  }

  func configure() {
    backDevice = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices.first
    guard let device = backDevice else { return }
    var bestFormat: AVCaptureDevice.Format?
    var bestFrameRateRange: AVFrameRateRange?
    for format in device.formats {
      for range in format.videoSupportedFrameRateRanges {
        guard bestFrameRateRange != nil else {
          bestFormat = format
          bestFrameRateRange = range
          continue
        }
        if Double(bestFrameRateRange!.maxFrameRate) < Double((range as AnyObject).maxFrameRate) {
          bestFormat = format
          bestFrameRateRange = range
        }
      }
    }
    do {
      try device.lockForConfiguration()
      defer { device.unlockForConfiguration() }
      device.activeFormat = bestFormat!
      device.activeVideoMinFrameDuration = bestFrameRateRange?.minFrameDuration ?? kCMTimeZero
      device.activeVideoMaxFrameDuration = bestFrameRateRange?.maxFrameDuration ?? kCMTimeZero

      device.torchMode = .off

      if device.isFocusModeSupported(.continuousAutoFocus) {
        device.focusMode = .continuousAutoFocus
      } else if device.isFocusModeSupported(.autoFocus) {
        device.focusMode = .autoFocus
      }
      if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
        device.whiteBalanceMode = .continuousAutoWhiteBalance
      } else if device.isWhiteBalanceModeSupported(.autoWhiteBalance) {
        device.whiteBalanceMode = .autoWhiteBalance
      }
      if device.isExposureModeSupported(.continuousAutoExposure) {
        device.exposureMode = .continuousAutoExposure

      } else if device.isExposureModeSupported(.autoExpose) {
        device.exposureMode = .autoExpose
      }
    } catch {
      debugPrint("error in \(#function): \(error)")
    }

    do {
      backInput = try AVCaptureDeviceInput(device: backDevice!)
    } catch {
      debugPrint("Failed to create device inputs because \(error)")
    }
  }

  public func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {

    guard let device = backDevice else { return }
    do {
      try device.lockForConfiguration()

      if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
        device.focusPointOfInterest = devicePoint
        device.focusMode = focusMode
      }

      if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
        device.exposurePointOfInterest = devicePoint
        device.exposureMode = exposureMode
      }

      device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
      device.unlockForConfiguration()
    } catch {
      debugPrint(error)
    }
  }
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
      let prediction = try GozAlmostuge().prediction(image: scaledBuffer)
      predictionPlacement = orderedFirstNInferences(n: numInferences, dict: prediction.breedProbability)
      predictionImage = frameImage
      DispatchQueue.main.async { self.performSegue(withIdentifier: "inference", sender: self) }
    } catch {
      debugPrint(error)
    }
  }
}
