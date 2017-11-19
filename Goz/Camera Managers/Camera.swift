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

  static var shared = Camera()

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

  func begin() {
    guard !captureSession.isRunning else { return }
    deviceQueue.async {
      self.captureSession.startRunning()
    }
  }

  func startSession(delly: CameraPresenter, sights: InsightPresenter) {
    presenter = delly
    insight = sights
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

  func captureOutput(_ captureOutput: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    debugPrint("dropped video output")
  }

  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard Bundle(for: GozRes.self).url(forResource: "GozRes", withExtension:"mlmodelc") != nil else { return }
    poorPredict(using: sampleBuffer, connection: connection)
  }
}
