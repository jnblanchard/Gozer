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
import StoreKit

class CameraViewController: UIViewController {

  var insightController: InsightfulViewController? {
    return childViewControllers.first(where: { (vc) -> Bool in
      return vc is InsightfulViewController
    }) as? InsightfulViewController
  }

  var prevOr: UIDeviceOrientation = .portrait

  @IBOutlet var predictionIndicator: UIActivityIndicatorView!
  @IBOutlet var cameraParentView: UIView!
  @IBOutlet var cameraBarCollection: [UIView]!

  var previewLayer: AVCaptureVideoPreviewLayer?

  override var prefersStatusBarHidden: Bool { return true }
//  override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }

  var predictionImage: UIImage?
  var predictionPlacement: [(String, Double)?] = []
  var picking: Bool = false

  let picker = UIImagePickerController()

  override func viewDidLoad() {
    super.viewDidLoad()
    predictionIndicator.layer.borderColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0.4).cgColor
    predictionIndicator.layer.borderWidth = 1.0
    picker.delegate = self
    picker.allowsEditing = false
    picker.delegate = self
    picker.sourceType = .photoLibrary
    cameraParentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(focusAndExposeTap)))
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(orientationChanged),
                                           name: NSNotification.Name.UIDeviceOrientationDidChange,
                                           object: nil)
    guard UserDefaults.standard.object(forKey: "AppLaunch") != nil else {
      UserDefaults.standard.set(1, forKey: "AppLaunch")
      return
    }
    let temp = UserDefaults.standard.integer(forKey: "AppLaunch")+1
    UserDefaults.standard.set(temp, forKey: "AppLaunch")
    guard temp % 5 == 0 else { return }
    SKStoreReviewController.requestReview()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    UIView.setAnimationsEnabled(false)
    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
    UIView.setAnimationsEnabled(true)
    guard !CameraPlatform.isSimulator else { return }
    switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
    case .authorized:
      guard let ivc = self.insightController else { return }
      Camera.shared.startSession(delly: self, sights: ivc)
    case .denied:
      //ask for settings auth
      break
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
        if response {
          DispatchQueue.main.async {
            guard let ivc = self.insightController else { return }
            Camera.shared.startSession(delly: self, sights: ivc)
          }
        } else {
          debugPrint("rejection")
        }
      }
    case .restricted:
      // Continue with restriction
      break
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    Camera.shared.stopSession()
  }

  @objc func orientationChanged(notification: Notification) {
    let rawNewOrientation = notification.userInfo?["newOrientation"] as? Int
    let newOrientation = rawNewOrientation != nil ? UIDeviceOrientation(rawValue: rawNewOrientation!) : nil

    let orientation = newOrientation ?? UIDevice.current.orientation

    guard orientation == .portrait || orientation == .landscapeLeft || orientation == .landscapeRight else { return }
    guard orientation != prevOr else { return }
    prevOr = orientation

    UIView.animate(withDuration: 0.4) {
      for view in self.cameraBarCollection {
        guard view.tag != 7 else { continue }
        view.rotateViewForOrientations(orientation: orientation)
      }
    }

    insightController?.orientation = orientation
  }

  @IBAction func torchSwitch(_ sender: Any) {
    guard let device = Camera.shared.backDevice else { return }
    do {
      try device.lockForConfiguration()
      let torchSwitch = device.torchMode == .on
      device.torchMode = torchSwitch ? .off : .on
      guard let parentView = cameraBarCollection.first(where: { (temp) -> Bool in
        return temp.tag == 5
      }) else { return }
      var label: TorchLabel? {
        guard let temp = parentView.subviews.first(where: { (aView) -> Bool in
          return aView is TorchLabel
        }) else { return nil }
        return temp as? TorchLabel
      }
      guard let torchLabel = label else { return }
      if device.torchMode == .on {
        try device.setTorchModeOn(level: 0.7)
        torchLabel.on = false
      } else {
        torchLabel.on = true
      }
    } catch {
      debugPrint(error)
    }
  }

  @IBAction func upload(_ sender: Any) {
    present(picker, animated: true, completion: nil)
  }

  @IBAction func predictionPugTapped(_ sender: Any) {
    let connection = Camera.shared.photoOutput.connection(with: AVMediaType.video)
    guard let vOr = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue) else { return }
    connection?.videoOrientation = vOr
    Camera.shared.photoOutput.capturePhoto(with: AVCapturePhotoSettings(format: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]), delegate: self)
    /* Prediction curation 11/10/17
     guard predictionIndicator.tag != 14 else { return }
     predictionIndicator.startAnimating()
     predictions.removeAll()
     predictionIndicator.tag = 14
     */
  }

  @objc func focusAndExposeTap(_ gestureRecognizer: UITapGestureRecognizer) {
    guard let devicePoint = previewLayer?.captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view)) else { return }
    Camera.shared.focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    guard let ivc = segue.destination as? InferenceViewController else { return }
    ivc.placementData = predictionPlacement
    ivc.frame = predictionImage
    predictionPlacement.removeAll()
  }

  override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
}
