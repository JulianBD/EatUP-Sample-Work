//
//  EventReviewViewController.swift
//  Extract
//
//  Created by Julian Dorsey on 12/19/18.
//  Copyright © 2018 Srihari Mohan. All rights reserved.
//

import UIKit

class EventReviewViewController: UIViewController {
    
    var review: Int = 3
    var eventID: String?
    
    @IBOutlet weak var eventRV: UIView!
    @IBOutlet weak var restaurantLabel: UILabel!
    
    @IBOutlet weak var reviewPicker: UIPickerView!
    
    let pickerData = ["Poor", "Not great", "Average","Good", "Fantastic!"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        self.reviewPicker.delegate = self
        self.reviewPicker.dataSource = self
        initializePopup()
        EventDetailViewController.showAnimate(self.view)
    }
    
    func initializePopup() {
        eventRV.layer.borderWidth = 1
        eventRV.layer.borderColor = UIColor.clear.cgColor
        eventRV.layer.cornerRadius = 10
        eventRV.layer.masksToBounds = true
    }
    
    @IBAction func sendReview(_ sender: Any) {
        let parameters = ["user" : UserDefaults.standard.string(forKey: "userID") as! String,
                          "review" : review] as [String:AnyObject]
        let withPathExtension = String(format: "/eatup/events/%@/reviews", eventID!)
        
        /* Make the request */
        _ = ExtractClient.taskForPOSTMethod(withPathExtension: withPathExtension,
                                            parameters: parameters, headers: [:]) { (results, error) in
            if let error = error {
                print(error)
            } else {
                DispatchQueue.main.async {
                    EventReviewViewController.removeAnimate(self.view)
                }
            }
        }
    }
    
    @IBAction func dismissView(_ sender: Any) {
        EventReviewViewController.removeAnimate(self.view)
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

extension EventReviewViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 5
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.review = row + 1
    }
    
    
}
