//
//  TorchLabel.swift
//  Goz
//
//  Created by John N Blanchard on 11/11/17.
//  Copyright © 2017 JohnNBlanchard. All rights reserved.
//

import UIKit

@IBDesignable
class TorchLabel: UILabel {
  @IBInspectable
  public var on: Bool {
    set {
      let con = newValue ? "Off" : "On"
      text = "Torch\n\(con)"
    } get {
      guard let temp = text, temp.contains("On") else { return false }
      return true
    }
  }
}
