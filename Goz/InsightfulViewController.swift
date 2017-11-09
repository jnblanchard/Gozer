//
//  InsightfulViewController.swift
//  Goz
//
//  Created by John N Blanchard on 11/7/17.
//  Copyright © 2017 JohnNBlanchard. All rights reserved.
//

import UIKit

protocol Insights { func topPredictionsFromFrame(entry: [(String, Double)]) }

class InsightfulViewController: UIViewController {

  @IBOutlet var labels: [UILabel]!

  @IBOutlet var labStackView: UIStackView!

  var delegate: Insights?

  var orientation: UIDeviceOrientation = .portrait {
    didSet {
      UIView.animate(withDuration: 0.25) {
        switch self.orientation {
        case .landscapeRight:
          self.labStackView.axis = .horizontal
        case .landscapeLeft:
          self.labStackView.axis = .horizontal
        default:
          self.labStackView.axis = .vertical
        }
        for label in self.labels { label.rotateViewForOrientations(orientation: self.orientation) }
      }
    }
  }

  var predictions: [String : Double]? {
    didSet {
      guard var wholeDict = predictions else { return }
      var topTups = orderedFirstNInferences(n: labels.count, dict: wholeDict)
      for label in labels {
        let prediction = topTups[label.tag]
        label.text = "\(prediction.1.rounded(toPlaces: 3)) \n \(prediction.0.replacingOccurrences(of: "_", with: " "))"
      }
      delegate?.topPredictionsFromFrame(entry: topTups)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
}
