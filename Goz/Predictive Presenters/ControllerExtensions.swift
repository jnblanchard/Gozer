//
//  ControllerExtensions.swift
//  Goz
//
//  Created by John N Blanchard on 11/9/17.
//  Copyright © 2017 JohnNBlanchard. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

struct CameraPlatform {
  static var isSimulator: Bool {
    return TARGET_OS_SIMULATOR != 0
  }
}

let oreo = UIDevice.current.orientation

var numInferences: Int {
  return UserDefaults.standard.object(forKey: "numInferences") != nil ? UserDefaults.standard.integer(forKey: "numInferences") : 5
}

extension CameraViewController: CameraPresenter {
  func present(session: AVCaptureSession) {
    previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
    previewLayer!.frame = view.bounds
    view.layer.addSublayer(previewLayer!)
    view.bringSubview(toFront: cameraParentView)
    camera.begin()
  }

  func lastOrientation() -> UIDeviceOrientation {
    return prevOr
  }
}

extension UIViewController {
  func orderedFirstNInferences(n: Int, dict: [String : Double]) -> [(String, Double)] {
    var topTups: [(String,Double)] = []
    var temp = dict
    for _ in 0..<n {
      guard let entry = temp.first(where: { (row) -> Bool in
        return row.value == temp.values.max()
      }) else { continue }
      temp.removeValue(forKey: entry.key)
      topTups.append(entry)
    }
    return topTups
  }

  func present(inferences: [(String, Double)]) {
    var i = 0
    let inference = inferences.map { (place) -> String in
      i+=1
      return "\(i): \(place.0), \(place.1.rounded(toPlaces: 4)*100)%"
      }.reduce("") { (first, next) -> String in
        return "\(first)\n\(next)"
    }
    let alert = UIAlertController(title: "Prediction Curated", message: inference, preferredStyle: .alert)
    let okay = UIAlertAction(title: "okay", style: .default, handler: nil)
    alert.addAction(okay)
    self.present(alert, animated: true, completion: nil)
  }
}

extension CameraViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    guard !picking else { return }
    picking = true
    let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
    DispatchQueue.main.async { self.predictionImage = chosenImage }
    UIGraphicsBeginImageContextWithOptions(CGSize(width: inputWidth, height: inputHeight), false, 0.0)
    chosenImage.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: inputWidth, height: inputHeight)))

    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()

    guard let dogImg = scaledImage.toBuffer() else { return }

    guard let prediction = try? GozAlmostuge().prediction(image: dogImg) else { return }
    DispatchQueue.main.async {
      self.dismiss(animated: true) {
        self.predictionPlacement = self.orderedFirstNInferences(n: numInferences, dict: prediction.breedProbability)
        self.performSegue(withIdentifier: "inference", sender: self)
        self.picking = false
      }
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true, completion: nil)
  }
}
