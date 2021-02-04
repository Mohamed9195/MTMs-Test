//
//  LiftSideMenueViewController.swift
//  MTMs
//
//  Created by mohamed hashem on 04/02/2021.
//

import UIKit

class LiftSideMenueViewController: UIViewController {

    @IBOutlet var downMenu: [UIButton]!

    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIView.animateKeyframes(withDuration: 1,
                                    delay: 0,
                                    options: .beginFromCurrentState) {
                self.downMenu.forEach { button in
                    button.isHidden = false
                }
            } completion: { _ in

            }
        }
    }
    

    @IBAction func dismissLiftSideMenue(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

}
