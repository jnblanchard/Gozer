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

extension ViewController {
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

    guard let input = backInput else { return }
    if captureSession.canAddInput(input) {
      captureSession.addInput(input)
    }

    captureSession.commitConfiguration()

    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
    previewLayer!.frame = view.bounds
    view.layer.addSublayer(previewLayer!)
    view.bringSubview(toFront: cameraParentView)
    DispatchQueue.main.async { self.captureSession.startRunning() }
  }

  func stopSession() { DispatchQueue.main.async { self.captureSession.stopRunning() } }

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
}
