//
//  InferenceViewController.swift
//  Goz
//
//  Created by John N Blanchard on 11/9/17.
//  Copyright © 2017 JohnNBlanchard. All rights reserved.
//

import UIKit

class InferenceViewController: UIViewController {

  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

  @IBOutlet var stackView: UIStackView!
  @IBOutlet var imageView: UIImageView!
  var frame: UIImage?
  var placementData: [(String, Double)?] = [] {
    didSet {
      var i = 0
      let placements = placementData.filter({ (entry) -> Bool in
        return entry != nil
      }).map { (confirmation) -> String in
        i+=1
        return "\(confirmation!.1.rounded(toPlaces: 3)*100)%, \(confirmation!.0.replacingOccurrences(of: "_", with: " ").capitalized)"
      }
      DispatchQueue.main.async {
        for placement in placements {
          let label = UILabel()
          label.font = UIFont.boldSystemFont(ofSize: 25)
          label.textAlignment = .center
          label.text = placement
          label.numberOfLines = 0
          label.textColor = UIColor.white
          self.stackView.addArrangedSubview(label)
        }
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    imageView.image = frame
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
