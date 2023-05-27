//
//  TextViewEditMenuDelegate.swift
//  Teleprompter
//
//  Created by Matheus Freitas Martins on 26/05/23.
//

import UIKit
import ObjectiveC

class TextViewEditMenuDelegate: NSObject, UIEditMenuInteractionDelegate {
    weak var viewController: ViewController?
    
    func editMenuInteraction(_ interaction: UIEditMenuInteraction, shouldUpdateForSecondaryAction secondaryAction: UIEditMenuInteraction.SecondaryAction, withTouchAt touchLocation: CGPoint) -> Bool {
        return true
    }
    
    func editMenuInteraction(_ interaction: UIEditMenuInteraction, actionForMenu action: UIEditMenuInteraction.Action) -> UICommand? {
        switch action {
        case .bold:
            return UICommand(title: "Negrito", action: #selector(viewController?.toggleBold))
        case .changeColor:
            return UICommand(title: "Cor", action: #selector(viewController?.toggleColor))
        default:
            return nil
        }
    }
}


