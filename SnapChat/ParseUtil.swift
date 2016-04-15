//
//  UserUtil.swift
//  SnapChat
//
//  Created by Chris on 1/28/16.
//  Copyright © 2016 Chris Mendez. All rights reserved.
//

import UIKit
import Parse

//MARK: - Parse Registration

@objc protocol UserUtilDelegate {
    optional func didSignUp()
    optional func didSignIn()
    optional func didSignOut()
    optional func didForgot()
    optional func didFail(message:String)
}

class UserUtil {
    
    var delegate:UserUtilDelegate?

    func signUp(username:String, password:String){
        let user = PFUser()
            user.username = username
            user.email    = username
            user.password = password
            user.signUpInBackgroundWithBlock { (success, error) -> Void in
                if success == true {
                    self.delegate?.didSignUp!()
                } else {
                    self.delegate?.didFail!( (error?.userInfo["error"] as! String) )
                }
        }
    }
    
    func signIn(username:String, password:String){
        PFUser.logInWithUsernameInBackground(username, password: password) { (parseUser, error) -> Void in
            if parseUser != nil {
                self.delegate?.didSignIn!()
            } else {
                self.delegate?.didFail!( (error?.userInfo["error"] as! String) )
            }
        }
    }
    
    func signOut(){
        PFUser.logOut()
    }
    
    func logOut(){
        signOut()
    }
    
    func forgot(){
        
    }
        
    //Initialized in App Delegate
    func track(){
        Parse.setApplicationId(Config.parse.APPLICATION_ID, clientKey: Config.parse.CLIENT_ID)
        
        let object = ["appVersion":0.9]
        PFAnalytics.trackAppOpenedWithLaunchOptions(object)
    }
}

//MARK: - Parse Friendships

protocol FriendUtilDelegate {
    func relationshipDidComplete(users:NSArray)
    func relationshipDidFail(message:String)
}

class FriendUtil: QueryUtilDelegate {
    
    let KEY_FRIEND_RELATION = "friendsRelation"
    
    var delegate:FriendUtilDelegate?
    
    //Source: EditFriendsTableViewController
    func findFriendsForEdit(){
        //TODO: - This needs conditions so we ask only for friends
        let queryUtil = QueryUtil()
            queryUtil.queryUsers()
            queryUtil.delegate = self
    }
    
    //Source: FirnedsTableViewController
    func updateFriendships(){
        //A. Get the currentUser who is logged in
        let currentUser = PFUser.currentUser()
        //B. Get the currentUser's list friends from Parse
        let relation = currentUser?.objectForKey( KEY_FRIEND_RELATION ) as? PFRelation
        //C. Create a new query of the currentUser's friends
        let query = relation?.query()
            query?.orderByAscending("username")
            //D. Make the query
            query?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
               if error != nil {
                    self.delegate?.relationshipDidFail( (error?.userInfo["error"] as! String) )
                } else {
                    //E. Update the tableView
                    self.delegate?.relationshipDidComplete(objects!)
                }
            })
    }
    
    func queryDidComplete(users: NSArray) {
        self.delegate?.relationshipDidComplete(users)
    }
    func queryDidFail(message: String) {
        self.delegate?.relationshipDidFail(message)
    }
}

//MARK: - Parse Queries

protocol QueryUtilDelegate {
    func queryDidComplete(objects:NSArray)
    func queryDidFail(message:String)
}

class QueryUtil {
    var delegate:QueryUtilDelegate?
    
    func query(className:String, key:String, orderBy:String="username"){
        let query = PFQuery(className: className)
            query.whereKey(key, equalTo: (PFUser.currentUser()?.objectId)!)
            query.orderByDescending(orderBy)
            query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
                if error != nil{
                    self.delegate?.queryDidFail((error?.localizedDescription)!)
                } else {
                    self.delegate?.queryDidComplete(objects!)
                }
            }
    }
    
    func queryUsers(){
        let query = PFUser.query()
            query?.orderByAscending("username")
            query?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                if error != nil {
                    self.delegate?.queryDidFail("Oh oh, there seems to be an error. " + (error?.userInfo["error"] as! String))
                }
                else if objects?.count > 0 {
                    self.delegate?.queryDidComplete(objects!)
                }
                else {
                    self.delegate?.queryDidFail("Friends not found.")
                }
            })
    }
}