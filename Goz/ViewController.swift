//
//  ViewController.swift
//  Goz
//
//  Created by John N Blanchard on 11/6/17.
//  Copyright © 2017 JohnNBlanchard. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

  let model = AdultGoz()
  var bottomController: InsightfulViewController? {
    return childViewControllers.first(where: { (vc) -> Bool in
      return vc is InsightfulViewController
    }) as? InsightfulViewController
  }

  let videoBufferQueue = DispatchQueue(label: "Output",
                                       autoreleaseFrequency: .workItem)

  let captureSession = AVCaptureSession()
  let output = AVCaptureVideoDataOutput()

  var lastOrientation: UIDeviceOrientation = .portrait

  var backDevice: AVCaptureDevice?
  var backInput: AVCaptureInput?

  @IBOutlet var predictionIndicator: UIActivityIndicatorView!
  @IBOutlet var cameraParentView: UIView!
  @IBOutlet var cameraImageViews: [UIImageView]!
  
  var previewLayer: AVCaptureVideoPreviewLayer?

  override var prefersStatusBarHidden: Bool { return true }
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }
  override var shouldAutorotate: Bool { return true }

  var predictions: [[(String, Double)]] = [[]]
  var picking: Bool = false

  override func viewDidLoad() {
    super.viewDidLoad()
    configure()
    bottomController?.delegate = self
    cameraParentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(focusAndExposeTap)))
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(orientationChanged),
                                           name: NSNotification.Name.UIDeviceOrientationDidChange,
                                           object: nil)
  }

  @objc func orientationChanged(notification: Notification) {
    let rawNewOrientation = notification.userInfo?["newOrientation"] as? Int
    let newOrientation = rawNewOrientation != nil ? UIDeviceOrientation(rawValue: rawNewOrientation!) : nil

    let orientation = newOrientation ?? UIDevice.current.orientation

    guard orientation == .portrait || orientation == .landscapeLeft || orientation == .landscapeRight else { return }
    guard orientation != lastOrientation else { return }
    lastOrientation = orientation

    UIView.animate(withDuration: 0.4) {
      for imageView in self.cameraImageViews { imageView.rotateViewForOrientations(orientation: orientation) }
    }

    bottomController?.orientation = orientation
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    startSession()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    UIView.setAnimationsEnabled(false)
    let value = UIInterfaceOrientation.portrait.rawValue
    UIDevice.current.setValue(value, forKey: "orientation")
    UIView.setAnimationsEnabled(true)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    stopSession()
  }


  @IBAction func torchTapped(_ sender: Any) {
    guard let device = backDevice else { return }
    do {
      try device.lockForConfiguration()
      let torchSwitch = device.torchMode == .on
      device.torchMode = torchSwitch ? .off : .on
      guard let imageView = cameraImageViews.first(where: { (temp) -> Bool in
        return temp.tag == 5
      }) else { return }
      if device.torchMode == .on {
        try device.setTorchModeOn(level: 0.7)
        imageView.image = #imageLiteral(resourceName: "candleOn")
      } else {
        imageView.image = #imageLiteral(resourceName: "candleOff")
      }
    } catch {
      debugPrint(error)
    }
  }

  @IBAction func uploadTapped(_ sender: Any) {
    let picker = UIImagePickerController()
    picker.allowsEditing = false
    picker.delegate = self
    picker.sourceType = .photoLibrary
    present(picker, animated: true, completion: nil)
  }

  @IBAction func predictionPugTapped(_ sender: Any) {
    predictionIndicator.startAnimating()
    predictions.removeAll()
    predictionIndicator.tag = 14
  }

  @objc func focusAndExposeTap(_ gestureRecognizer: UITapGestureRecognizer) {
    guard let devicePoint = previewLayer?.captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view)) else { return }
    focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
  }

  func captureOutput(_ captureOutput: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    //debugPrint("dropped video output")
  }

  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    poorPredict(using: sampleBuffer)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}

  override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
}
