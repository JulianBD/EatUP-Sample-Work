/*
EventCreationViewController.swift
EatUP
*/

import UIKit
import FBSDKLoginKit
import AccountKit
import FBSDKCoreKit

class EventCreationViewController: UIViewController {
    
    // Facebook and AccountKit Login variables
    fileprivate var accountKit = AKFAccountKit(responseType: .accessToken)
    
    fileprivate let isAccountKitLogin: Bool = {
        return AKFAccountKit(responseType: .accessToken).currentAccessToken != nil
    }()
    
    fileprivate let isFacebookLogin: Bool = {
        return FBSDKAccessToken.current() != nil
    }()
    
    var friends = [[String : String]]()
    var emails = [String]()
    var friendIDs = [String]()
    
    @IBOutlet weak var eventNameLabel: UITextField!
    @IBOutlet weak var eventTimeLabel: UITextField!
    @IBOutlet weak var eventTimeBeforeLabel: UITextField!
    @IBOutlet weak var friendList: UITableView!
    
    var datePickerBeforeTime = UIDatePicker()
    var datePickerStartTime = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        friendList.delegate = self
        friendList.dataSource = self
        self.initializeDatePicker(datePicker: datePickerBeforeTime)
        self.initializeDatePicker(datePicker: datePickerStartTime)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(EventCreationViewController.viewTapped(gestureRecognizer:)))
        
        view.addGestureRecognizer(tapGesture)
        
        eventTimeLabel.inputView = datePickerStartTime
        eventTimeBeforeLabel.inputView = datePickerBeforeTime
        
        FBSDKGraphRequest(graphPath: "me/friends",
                          parameters: ["fields": "id, name"]).start(
                            completionHandler: { (connection, result, error) -> Void in
            if (error == nil) {
                if let data = result as? [String:Any] {
                    self.friends = data["data"] as? [[String: Any]] as! [[String : String]]
                    DispatchQueue.main.async {
                        self.friendList.reloadData()
                    }
                }
            }
        })
    }
    
    func initializeDatePicker(datePicker: UIDatePicker) {
        datePicker.datePickerMode = .dateAndTime
        datePicker.addTarget(self, action: #selector(EventCreationViewController.eventDateChanged(datePicker:)), for: .valueChanged)
    }
    
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @objc func eventDateChanged(datePicker: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd-hh:mm"
        eventTimeLabel.text = dateFormatter.string(from: datePickerStartTime.date)
        eventTimeBeforeLabel.text = dateFormatter.string(from: datePickerBeforeTime.date)
        view.endEditing(true)
    }
    
    @IBAction func createEvent(_ sender: Any) {
        var parameters = ["fbIDs" : friendIDs] as [String:AnyObject]
        let withPathExtension = "/eatup/users/usersByfbID"
        
        /* Make the request */
        _ = ExtractClient.taskForPOSTMethod(withPathExtension: withPathExtension,
                                            parameters: parameters, headers: [:]) { (results, error) in
                if let error = error {
                    print("IT's the EVENT ERROR: " + "\(error)")
                } else {
                    if let data = results?["users"] as? [[String: AnyObject]] {
                        var reqIDs = [String]()
                        for friend in data {
                            reqIDs.append(friend["_id"] as! String)
                        }
                        parameters = [ExtractClient.ParameterKeys.Admin : UserDefaults.standard.string(forKey: "userID") as AnyObject,
                        ExtractClient.ParameterKeys.Time : self.eventTimeLabel.text as AnyObject,
                        ExtractClient.ParameterKeys.TimeBefore : self.eventTimeBeforeLabel.text as AnyObject,
                        ExtractClient.ParameterKeys.Members : reqIDs as AnyObject,
                        ExtractClient.ParameterKeys.Name : self.eventNameLabel.text] as [String: AnyObject]
                        let eventPathExtension = "/eatup/events/new"
                        /* Make the request */
                        _ = ExtractClient.taskForPOSTMethod(withPathExtension: eventPathExtension,
                                                            parameters: parameters, headers: [:]) { (results, error) in
                            if let error = error {
                                print("IT's the EVENT ERROR: " + "\(error)")
                            } else {
                                DispatchQueue.main.async {
                                    self.performSegue(withIdentifier: "toEventList", sender: nil)
                                }
                            }
                        }
                    }
                }
            }
        }
}

extension EventCreationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.friends.count == 0 {
            return 1
        } else {
            return friends.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = friendList.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath) as! FriendCell
        if friends.count == 0 {
            cell.friendLabel.text = "No Facebook friends using EatUP"
            
        } else {
            cell.friendLabel.text = self.friends[indexPath.row]["name"]
            cell.friendID = self.friends[indexPath.row]["id"]
            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        let currentCell = friendList.cellForRow(at: indexPath) as! FriendCell
        self.friendIDs.append(currentCell.friendID)
        print(self.friendIDs)
    }
    
    func tableView(_ tableView: UITableView,
                   didDeselectRowAt indexPath: IndexPath) {
        let currentCell = friendList.cellForRow(at: indexPath) as! FriendCell
        if let index = self.friendIDs.index(of:currentCell.friendID) {
            self.friendIDs.remove(at: index)
        }
        print(self.friendIDs)
    }
}
