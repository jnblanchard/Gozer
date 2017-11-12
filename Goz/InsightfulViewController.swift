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

  @IBOutlet var labStackView: UIStackView!

  var delegate: Insights?

  var insightCount: Int {
    //return numInferences
    return 4
  }

  var orientation: UIDeviceOrientation = .portrait {
    didSet {
      UIView.animate(withDuration: 0.5) {
        switch self.orientation {
        case .landscapeRight:
          self.labStackView.axis = .horizontal
        case .landscapeLeft:
          self.labStackView.axis = .horizontal
        default:
          self.labStackView.axis = .vertical
        }
        for label in self.labStackView.arrangedSubviews {
          label.rotateViewForOrientations(orientation: self.orientation)
        }
      }
    }
  }

  var predictions: [String : Double]? {
    didSet {
      guard let wholeDict = predictions else { return }
      let inferences = orderedFirstNInferences(n: insightCount, dict: wholeDict)
      for label in labStackView.arrangedSubviews {
        guard let temp = label as? UILabel, let i = labStackView.arrangedSubviews.index(of: temp) else { continue }
        guard i < inferences.count else { continue }
        let prediction = inferences[i]
        temp.text = "\(prediction.1.rounded(toPlaces: 3)*100)%, \(prediction.0.replacingOccurrences(of: "_", with: " ").capitalized)"
      }
      delegate?.topPredictionsFromFrame(entry: inferences)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    for i in 0..<insightCount {
      let label = UILabel()
      label.tag = i
      label.adjustsFontSizeToFitWidth = true
      label.minimumScaleFactor = 0.8
      label.textAlignment = .center
      label.font = UIFont(name: "Futura-Medium", size: 15)
      label.autoresizingMask = .flexibleWidth
      label.numberOfLines = 0
      label.textColor = UIColor.white
      labStackView.addArrangedSubview(label)
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
}
