/*
EventDetailViewController.swift
EatUP
*/

import UIKit

class EventDetailViewController: UIViewController {
    
    @IBOutlet weak var eventPUView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var memberText: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        initializePopup()
        EventDetailViewController.showAnimate(self.view)
    }
    
    func initializePopup() {
        eventPUView.layer.borderWidth = 1
        eventPUView.layer.borderColor = UIColor.clear.cgColor
        eventPUView.layer.cornerRadius = 10
        eventPUView.layer.masksToBounds = true
    }
    
    @IBAction func leavePopUp(_ sender: AnyObject) {
        EventDetailViewController.removeAnimate(self.view)
    }
    
    static func showAnimate(_ view: UIView)
    {
        view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            view.alpha = 1.0
            view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        });
    }
    
    static func removeAnimate(_ view: UIView)
    {
        UIView.animate(withDuration: 0.25, animations: {
            view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            view.alpha = 0.0;
        }, completion:{(finished : Bool)  in
            if (finished){
                view.removeFromSuperview()
            }
        });
    }
}
