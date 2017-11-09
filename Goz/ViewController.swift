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

  var backDevice: AVCaptureDevice?
  var backInput: AVCaptureInput?

  @IBOutlet var predictionIndicator: UIActivityIndicatorView!
  @IBOutlet var cameraParentView: UIView!
  var previewLayer: AVCaptureVideoPreviewLayer?

  override var prefersStatusBarHidden: Bool { return true }
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }
  override var shouldAutorotate: Bool { return true }

  var predictions: [[(String, Double)]] = [[]]

  override func viewDidLoad() {
    super.viewDidLoad()
    configure()
    bottomController?.delegate = self
    cameraParentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(focusAndExposeTap)))
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

  @IBAction func sparkPredictionTapped(_ sender: Any) {
    predictionIndicator.startAnimating()
    predictions.removeAll()
    predictionIndicator.tag = 14
  }

  @objc func focusAndExposeTap(_ gestureRecognizer: UITapGestureRecognizer) {
    guard let devicePoint = previewLayer?.captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view)) else { return }
    focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
  }

  @IBAction func torchButtonTapped(_ sender: UIButton) {
    guard let device = backDevice else { return }
    do {
      try device.lockForConfiguration()
      let torchSwitch = device.torchMode == .on
      device.torchMode = torchSwitch ? .off : .on
      if device.torchMode == .on {
        try device.setTorchModeOn(level: 0.7)
      }
      sender.setTitle(torchSwitch ? "TorchON" : "TorchOFF", for: .normal)
    } catch {
      debugPrint(error)
    }
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
