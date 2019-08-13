//
//  ViewController.swift
//  SlideTransition
//
//  Created by Dmitry Kuzin on 08/13/2019.
//  Copyright (c) 2019 Dmitry Kuzin. All rights reserved.
//

import UIKit
import SlideTransition

class ViewController: UIViewController {

    enum ControllerType: String {
        case yellow = "YellowViewController"
        case blue = "BlueViewController"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: - Actions
    
    @IBAction func yellowButtonDidTap(_ sender: UIButton) {
        presentController(.yellow)
    }
    
    @IBAction func blueButtonDidTap(_ sender: UIButton) {
        presentController(.blue)
    }
    
    private func presentController(_ controllerType: ControllerType) {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: controllerType.rawValue) else { return }
        let configuration = SlideTransitionConfigurator()
//        configuration.
        slidePresent(controller, animated: true)
    }

}


