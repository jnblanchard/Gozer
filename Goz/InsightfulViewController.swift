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

  var delegate: Insights?

  var predictions: [String : Double]? {
    didSet {
      guard var wholeDict = predictions else { return }
      var topTups: [(String,Double)] = []
      for _ in 0..<labels.count {
        guard let entry = wholeDict.first(where: { (row) -> Bool in
          return row.value == wholeDict.values.max()
        }) else { continue }
        wholeDict.removeValue(forKey: entry.key)
        topTups.append(entry)
      }
      for label in labels {
        let prediction = topTups[label.tag]
        label.text = "\(prediction.1.rounded(toPlaces: 3)) \n \(prediction.0)"
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
