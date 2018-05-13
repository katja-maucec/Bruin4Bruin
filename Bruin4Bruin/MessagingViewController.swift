//
//  MessagingViewController.swift
//  Bruin4Bruin
//
//  Created by Changyuan Lin on 5/4/18.
//  Copyright © 2018 Changyuan Lin. All rights reserved.
//

import UIKit
import Firebase

class MessagingViewController: UIViewController, UITableViewDataSource {
    
    var handle: AuthStateDidChangeListenerHandle?
    let db = Firestore.firestore()
    var messages = [QueryDocumentSnapshot]()
    var userDocumentListener: ListenerRegistration?
    var messagesListener: ListenerRegistration?
    
    @IBOutlet weak var messagingTableView: UITableView!
    @IBOutlet weak var messageField: UITextField!
    
    var email = ""
    var uid = ""
    var currentchat = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        messagingTableView.dataSource = self
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in  // This gets the authenticated user's info
            if let user = user {
                print("\(type(of: self)) updating user info")
                self.email = user.email!
                self.uid = user.uid
                self.addUserDocumentListener()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
        userDocumentListener?.remove()
        messagesListener?.remove()
        // Are these in the right order??
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MessagingTableViewCell", for: indexPath) as? MessagingTableViewCell else {
            fatalError("Dequed cell is not MessagingTableViewCell!")
        }
        
        if let content = messages[indexPath.row].data()["content"] as? String {
            cell.message.text = content
        }
        if let time = messages[indexPath.row].data()["timestamp"] as? Timestamp {
            cell.timestamp.text = DateFormatter.localizedString(from: time.dateValue(), dateStyle: .medium, timeStyle: .medium)
        }
        if let from = messages[indexPath.row].data()["from"] as? String {
            if from == uid {
                cell.setRight()
            } else {
                cell.setLeft()
            }
        } else {
            cell.setLeft()  // Shouldn't be used but here for testing purposes since not all have "from"
        }
        
        return cell
    }
    
    func addUserDocumentListener() {
        userDocumentListener = db.collection("users").document(uid).addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            print(document.data())
            if let chat = document.data()!["currentchat"] as? String {
                self.currentchat = chat  // Update the user's current chat room
                self.addMessagesListener()  // Do it here so currentchat is something
            }
        }
    }
    
    func addMessagesListener() {
        messagesListener = db.collection("chats").document(currentchat).collection("messages").order(by: "timestamp").addSnapshotListener { querySnapshot, error in  // Listens for updates to messages
            guard let documents = querySnapshot?.documents else {
                print("Error getting documents!: \(error!)")
                return
            }
            self.messages = documents  // Reloads everything, not necessarily the most efficient but it's simple
            self.messagingTableView.reloadData()  // Otherwise the table won't update when loads new messages
            let content = documents.map { $0["content"]! }
            print("Messages: \(content)")
        }
    }
    
    @IBAction func settingsPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "MessagingToSettings", sender: nil)
    }
    
    @IBAction func profilePressed(_ sender: UIBarButtonItem) {
        // View the other person's profile
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        if let text = messageField.text, !text.isEmpty, !currentchat.isEmpty {
            print("Sending: \(text)")
            messageField.text = ""
            db.collection("chats").document(currentchat).collection("messages").addDocument(data: [  // Hopefully by the time the first message is sent we already know what currentchat is actually i'll just add a check in the big if statement
                "content" : text,
                "from" : uid,
                "timestamp" : Timestamp()
            ]) { err in
                if let err = err {
                    print("Error adding document: \(err)")
                } else {
                    print("Successfully sent: \(text)")
                }
            }
        } else {
            print("Message is blank or currentchat is not set")
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func unwindToMessaging(segue: UIStoryboardSegue) {
        // unwind to messaging
    }

}
