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

  func getAtr(big: Bool) -> [NSAttributedStringKey: Any]? {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    if big {
      return  [
        NSAttributedStringKey.font: UIFont(name: "Futura-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16),
        NSAttributedStringKey.foregroundColor: UIColor.white,
        NSAttributedStringKey.paragraphStyle: style
      ]
    } else {
      return [
        NSAttributedStringKey.font: UIFont(name: "Futura-Medium", size: 14) ?? UIFont.boldSystemFont(ofSize: 14),
        NSAttributedStringKey.foregroundColor: UIColor.white,
        NSAttributedStringKey.paragraphStyle: style
      ]
    }
  }

  @IBInspectable
  public var on: Bool {
    set {
      let firstPart = NSMutableAttributedString(string: "Torch\n", attributes: getAtr(big: true) )
      let con = on ? "Off" : "On"
      let secondPart = NSAttributedString(string: con, attributes: getAtr(big: false))
      firstPart.append(secondPart)
      attributedText = firstPart
    } get {
      guard let temp = text, temp.contains("On") else { return false }
      return true
    }
  }

}
