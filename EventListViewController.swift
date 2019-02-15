/*
EventListViewController.swift
EatUP
*/

import UIKit
import AccountKit
import FBSDKLoginKit
import CoreLocation

class EventListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var locManager = CLLocationManager()
    var currentLocation: CLLocation!
    
    var email = ""
    var firstname = ""
    var lastname = ""
    var userid = ""
    
    var events = [Event]()
    
    // Facebook and AccountKit Login variables
    fileprivate var accountKit = AKFAccountKit(responseType: .accessToken)
    
    fileprivate let isAccountKitLogin: Bool = {
        return AKFAccountKit(responseType: .accessToken).currentAccessToken != nil
    }()
    
    fileprivate let isFacebookLogin: Bool = {
        return FBSDKAccessToken.current() != nil
    }()
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    struct TableViewCellIdentifiers {
        static let eventCell = "EventCell"
        static let nothingFoundCell = "NothingFoundCell"
    }
    
    override func viewDidLayoutSubviews() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locManager.requestWhenInUseAuthorization()
        getUserInfo()
        initializeTableView()
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func initializeTableView() {
        tableView.allowsSelection = true
        tableView.rowHeight = 80
        var cellNib = UINib(nibName: TableViewCellIdentifiers.eventCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.eventCell)
        cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func requestAccountKit() {
        accountKit.requestAccount { [weak self] (account, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                if let emailAddress = account?.emailAddress, emailAddress.characters.count > 0 {
                    self?.email = emailAddress
                    self?.appDelegate.email = self?.email
                    UserDefaults.standard.set(emailAddress, forKey: "email")
                }
            }
        }
    }
    
    func requestFacebook() {
        FBSDKGraphRequest(graphPath: "me",
                          parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email , gender"]).start(
                            completionHandler: { (connection, result, error) -> Void in
            if (error == nil) {
                if let data = result as? [String:Any] {
                    UserDefaults.standard.set(data["id"] as! String, forKey: "fbID")
                    self.email = data["email"] as! String
                    self.appDelegate.email = self.email
                    UserDefaults.standard.set(data["email"] as! String, forKey: "email")
                    self.firstname = data["first_name"] as! String
                    self.appDelegate.firstname = self.firstname
                    UserDefaults.standard.set(data["first_name"] as! String, forKey: "first-name")
                    self.lastname = data["last_name"] as! String
                    self.appDelegate.lastname = self.lastname
                    UserDefaults.standard.set(data["last_name"] as! String, forKey: "last-name")
                    self.getUserCredentialsOnLogin()
                }
            }
        })
    }
    
    func getUserInfo() {
        if isAccountKitLogin {
            requestAccountKit()
        } else if isFacebookLogin {
            requestFacebook()
        }
    }
    
    func getUserCredentialsOnLogin() {
        
        // make request to Eatup API
        if(CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() ==  .authorizedAlways) {
            print(locManager)
            if let location = locManager.location {
                currentLocation = location
            } else {
                //set default location to JHU in case of location service failure bug
                currentLocation = CLLocation(latitude: 39.3289, longitude: -76.617270)
            }
        }
        
        if currentLocation != nil {
            
            let latitude = Int(currentLocation.coordinate.latitude)
            let longitude = Int(currentLocation.coordinate.longitude)
            
            let parameters = [ExtractClient.ParameterKeys.FirstName: UserDefaults.standard.string(forKey: "first-name") as AnyObject,
                              "fbID" : UserDefaults.standard.string(forKey: "fbID") as AnyObject,
                              ExtractClient.ParameterKeys.LastName: UserDefaults.standard.string(forKey: "last-name") as AnyObject,
                              ExtractClient.ParameterKeys.Email: UserDefaults.standard.string(forKey: "email") as AnyObject,
                              ExtractClient.ParameterKeys.Latitude: latitude as AnyObject,
                              ExtractClient.ParameterKeys.Longitude: longitude as AnyObject] as [String: AnyObject]
            print(parameters)
            let withPathExtension = "/eatup/users/new"
            
            /* Make the request */
            _ = ExtractClient.taskForPOSTMethod(withPathExtension: withPathExtension,
                                                parameters: parameters, headers: [:]) { (results, error) in
                if let error = error {
                    print("IT'S the USER ERROR: " + "\(error)")
                } else {
                    self.userid = results?["_id"] as! String
                    self.appDelegate.userid = self.userid
                    UserDefaults.standard.set(results?["_id"] as! String, forKey: "userID")
                    print(UserDefaults.standard.string(forKey: "userID"))
                    self.refreshEvents(userID: UserDefaults.standard.string(forKey: "userID")!)
                }
            }
        }
    }
    
    func refreshEvents(userID: String) {
        self.events = [Event]()
        let withPathExtension = String(format: "/eatup/users/%@/events", UserDefaults.standard.string(forKey: "userID") ?? "")
        _ = ExtractClient.taskForGETMethod(withPathExtension: withPathExtension, parameters: [:], headers: [:]) { (results, error) in
            /* Send the desired value(s) to completion handler */
            if let error = error {
                print(error)
            } else {
                if let eventList = results?[ExtractClient.JSONResponseKeys.Events] as? [[String: AnyObject]] {
                    print(eventList.count)
                    for event in eventList {
                        if event[ExtractClient.JSONResponseKeys.Admin] == nil {
                            continue
                        }
                        let id = event[ExtractClient.JSONResponseKeys.ID] as! String
                        let admin = event[ExtractClient.JSONResponseKeys.Admin] as! String
                        let name = event[ExtractClient.JSONResponseKeys.Name] as! String
                        let chat = event[ExtractClient.JSONResponseKeys.Chat] as! [[String: AnyObject]]
                        let members = event[ExtractClient.JSONResponseKeys.Members] as! [String]
                        let rec = event[ExtractClient.JSONResponseKeys.Recommendation] as! String
                        let time = event[ExtractClient.JSONResponseKeys.Time] as! String
                        let time_before = event[ExtractClient.JSONResponseKeys.TimeBefore] as! String
                        self.events.append(Event(_id: id, admin: admin, name: name, chat: chat, members: members,
                                                 rec: rec, time: time, time_before: time_before))
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    @IBAction func logout(_ sender: Any) {
        print(isAccountKitLogin)
        print(isFacebookLogin)
        if isAccountKitLogin {
            accountKit.logOut()
        } else {
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
        }
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
        let _ = navigationController?.popToRootViewController(animated: true)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true;
    }
    
    @IBAction func addEvent(_ sender: Any) {
        // TODO: implement add event functionality
    }
}

extension EventListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if events.count == 0 {
            return 1
        } else {
            return events.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if events.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.nothingFoundCell, for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.eventCell, for: indexPath) as! EventCell
            let event = events[indexPath.row]
            cell.eventNameLabel.text = event.name
            cell.recLabel.text = event.rec.isEmpty ? "No Recommendations" : event.rec
            cell.timeLabel.text = event.time
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //tableView.deselectRow(at: indexPath, animated: true)
        let event = self.events[indexPath.row]
        let chatVC = self.storyboard?.instantiateViewController(withIdentifier: "ExtractViewController") as! ExtractViewController
        chatVC.eventID = event._id
        chatVC.userID = self.userid
        chatVC.time = event.time
        chatVC.rec = event.rec
        self.present(chatVC, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if events.count == 0 {
            return nil
        } else {
            return indexPath
        }
    }
}
