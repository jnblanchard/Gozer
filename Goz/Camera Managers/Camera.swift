//
//  Camera.swift
//  Goz
//
//  Created by John N Blanchard on 11/14/17.
//  Copyright © 2017 JohnNBlanchard. All rights reserved.
//

import UIKit
import AVFoundation

class Camera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

  static var shared: Camera? {
    guard AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized else { return nil }
    return Camera()
  }

  let deviceQueue = DispatchQueue(label: "Device", autoreleaseFrequency: .workItem)
  let videoBufferQueue = DispatchQueue(label: "Output", autoreleaseFrequency: .workItem)

  let captureSession = AVCaptureSession()
  let photoOutput = AVCapturePhotoOutput()
  let output = AVCaptureVideoDataOutput()

  var backDevice: AVCaptureDevice?
  var backInput: AVCaptureInput?

  var presenter: CameraPresenter?
  var insight: InsightPresenter?

  override init() {
    guard !CameraPlatform.isSimulator else {
      backDevice = nil
      super.init()
      return
    }
    backDevice = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices.first
    super.init()
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
      backInput = try AVCaptureDeviceInput(device: device)
    } catch {
      debugPrint("Failed to create device inputs because \(error)")
    }
  }

  func captureOutput(_ captureOutput: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    //debugPrint("dropped video output")
  }

  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    poorPredict(using: sampleBuffer, connection: connection)
  }
}
