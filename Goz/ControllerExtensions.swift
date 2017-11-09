//
//  ControllerExtensions.swift
//  Goz
//
//  Created by John N Blanchard on 11/9/17.
//  Copyright © 2017 JohnNBlanchard. All rights reserved.
//

import Foundation
import UIKit

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

extension ViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    guard !picking else { return }
    picking = true
    let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
    UIGraphicsBeginImageContextWithOptions(CGSize(width: 300, height: 400), false, 0.0)
    chosenImage.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: 300, height: 400)))

    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()

    guard let dogImg = scaledImage.toBuffer() else { return }

    guard let prediction = try? self.model.prediction(data: dogImg) else { return }
    DispatchQueue.main.async {
      self.dismiss(animated: true) {
        let topPredictions = self.orderedFirstNInferences(n: 3, dict: prediction.breedProbability)
        self.present(inferences: topPredictions)
        self.picking = false
      }
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true, completion: nil)
  }
}
