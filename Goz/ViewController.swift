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
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }
  override var shouldAutorotate: Bool { return true }

  var predictions: [[(String, Double)]] = [[]]

  override func viewDidLoad() {
    super.viewDidLoad()
    bottomController?.delegate = self
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

  @IBAction func sparkPredictionTapped(_ sender: Any) {
    predictions.removeAll()
    predictionLabel.tag = 14
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

extension ViewController: Insights {
  func consensus(on place: Int) -> String? {
    guard place < predictions.count else {
      debugPrint("Attempting to create consensus on out of bounds placement.")
      return nil
    }
    let topMap = predictions.map { (entry) -> String? in
      return entry[place].0
    }
    var count: [String: Int] = [:]
    for item in topMap {
      guard let temp = item else { continue }
      count[temp] = (count[temp] ?? 0) + 1
    }
    guard let temp = count.first(where: { (entry) -> Bool in
      return entry.value == count.values.max()
    }) else { return nil }
    return temp.key
  }

  func curatePrediction() {
    let first = "1. \(consensus(on: 0) ?? "")"
    let second = "2. \(consensus(on: 1) ?? "")"
    let third = "3. \(consensus(on: 2) ?? "")"
    let alert = UIAlertController(title: "Prediction Curated", message: "\(first)\n\(second)\n\(third)", preferredStyle: .alert)
    let okay = UIAlertAction(title: "okay", style: .default, handler: nil)
    alert.addAction(okay)
    present(alert, animated: true, completion: nil)
    predictions.removeAll()
  }


  func topPredictionsFromFrame(entry: [(String, Double)]) {
    guard predictionLabel.tag == 14 else { return }
    guard predictions.count < 18 else {
      predictionLabel.tag = 2
      curatePrediction()
      return
    }
    predictions.append(entry)
  }
}
