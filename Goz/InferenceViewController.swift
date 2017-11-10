//
//  InferenceViewController.swift
//  Goz
//
//  Created by John N Blanchard on 11/9/17.
//  Copyright © 2017 JohnNBlanchard. All rights reserved.
//

import UIKit

class InferenceViewController: UIViewController {

  @IBOutlet var stackView: UIStackView!

  var placementData: [(String, Double)?] = [] {
    didSet {
      var i = 0
      let placements = placementData.filter({ (entry) -> Bool in
        return entry != nil
      }).map { (confirmation) -> String in
        i+=1
        return "\(confirmation!.1.rounded(toPlaces: 4)*100)%: \(confirmation!.0.replacingOccurrences(of: "_", with: " "))"
      }
      DispatchQueue.main.async {
        for placement in placements {
          let label = UILabel()
          label.font = UIFont(name: "Futura-Medium", size: 25)
          label.textAlignment = .center
          label.text = placement
          label.textColor = UIColor.white
          self.stackView.addArrangedSubview(label)
        }
        self.view.layoutIfNeeded()
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    UIView.setAnimationsEnabled(false)
    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
    UIView.setAnimationsEnabled(true)
  }

  @IBAction func dismissTapped(_ sender: Any) {
    dismiss(animated: true, completion: nil)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
}
