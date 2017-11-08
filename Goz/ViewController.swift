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

  let videoBufferQueue = DispatchQueue(label: "Video Output",
                                       autoreleaseFrequency: .workItem)
  let deviceSessionQueue = DispatchQueue(label: "Device Actions")

  let captureSession = AVCaptureSession()
  let output = AVCaptureVideoDataOutput()

  var backDevice: AVCaptureDevice?
  var backInput: AVCaptureInput?

  @IBOutlet var cameraParentView: UIView!
  @IBOutlet var predictionLabel: UILabel!
  @IBOutlet var predictionImageView: UIImageView!
  var previewLayer: AVCaptureVideoPreviewLayer?

  override var prefersStatusBarHidden: Bool { return true }

  override func viewDidLoad() {
    super.viewDidLoad()
    configure()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    startSession()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    stopSession()
  }

  func captureOutput(_ captureOutput: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    //debugPrint("dropped video output")
  }

  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    poorPredict(using: sampleBuffer)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

  }

  override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
}
