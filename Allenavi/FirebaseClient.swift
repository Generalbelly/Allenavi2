//
//  FirebaseClient.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/02/16.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation
import Firebase
import Alamofire
import SwiftyJSON
import GeoFire

enum SaveType {
    case AddResAndPost
    case AddPost
}

class FirebaseClient: NSObject {
    
    static let sharedInstance = FirebaseClient()
    let ref = FIRDatabase.database().reference()
    let postsRef = FIRDatabase.database().reference().child("posts")
    let usersRef = FIRDatabase.database().reference().child("users")
    let restaurantsRef = FIRDatabase.database().reference().child("restaurants")
    let geoFire: GeoFire?
    
    var image: UIImage?
    var commentId = ""
    var user: User?
    var place: Place?
    var food = ""
    var comment = ""
    var allergies = [String]()
    
    var timestamp: String {
        let currentDate = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd 'at' HH:mm"
        let convertedDate = dateFormatter.stringFromDate(currentDate)
        return convertedDate
    }
    
    override init() {
        let geofireRef = FIRDatabase.database().reference().child("resLocations")
        geoFire = GeoFire(firebaseRef: geofireRef)
    }
    
    func save(type: SaveType, info: [String: AnyObject]) {
        self.image = info["image"] as? UIImage
        self.place = info["place"] as? Place
        self.comment = info["comment"] as! String
        self.allergies = info["allergies"] as! [String]
        switch type {
        case .AddResAndPost:
            self.checkIfChain()
        default:
            self.saveAllergiesRelations(type, res: self.place!, allergies: self.allergies)
        }
    }
    
    func checkIfChain() {
        var data = [String: AnyObject]()
        data["name"] = self.place!.name
        data["formattedAddress"] = self.place!.address
        if self.place!.dbId == "" {
            self.place!.dbId = self.ref.childByAutoId().key
        }
        data["id"] = self.place!.dbId
        data["placeId"] = self.place!.placeId
        data["created_at"] = self.timestamp
        if self.place!.phoneNumber != nil {
            data["phone"] = self.place!.phoneNumber
        }
        if self.place!.name.containsString("店") {
            self.ref.child("chain_restaurants").observeSingleEventOfType(.Value, withBlock: { snapshot in
                let chainList = snapshot.children.allObjects
                for chainData in chainList {
                    let chain = chainData as! [String: AnyObject]
                    let chainName = chain["name"] as! String
                    let chainId = chain["id"] as! String
                    if self.place!.name.containsString(chainName) {
                        self.place!.chainId = chainId
                        data["chainId"] = chainId
                        self.saveRes(data)
                        break
                    }
                }
                if self.place!.chainId == nil {
                    self.saveRes(data)
                }
            })
        } else {
            self.saveRes(data)
        }
    }
    
    func saveRes(resData: [String: AnyObject]) {
        let resId = self.place!.dbId
        self.restaurantsRef.child(resId).setValue(resData)
        geoFire!.setLocation(CLLocation(latitude: self.place!.lat, longitude: self.place!.lon), forKey: resId)
        if self.place!.new {
            self.ref.child("newitems").child(resId).setValue(true)
        }
        print(resId)
        self.saveAllergiesRelations(.AddResAndPost, res: self.place!, allergies: self.allergies)
    }
    
    func createPost(itemData: [String: AnyObject]) -> Post {
        let post = Post()
        post.comment = itemData["comment"] as! String
        post.createdAt = itemData["created_at"] as! String
        post.id = itemData["id"] as! String
        if let data = itemData["allergies"] as? [String: Bool] {
            post.allergies = [String](data.keys)
        }
        post.userId = itemData["userId"] as! String
        post.user = itemData["user"] as! String
        post.resId = itemData["resId"] as! String
        
        post.userImage = itemData["userImage"] as! String
        post.imageUrl = itemData["image"] as! String
        return post
    }
    
    func createUser(itemData: [String: AnyObject]) -> User {
        let user = User()
        user.id = itemData["id"] as! String
        user.name = itemData["displayName"] as! String
        user.email = itemData["email"] as! String
        user.imageUrl = itemData["profileImageURL"] as? String
        if let data = itemData["posts"] as? [String: Bool] {
            user.postIds = [String](data.keys)
        }
        return user
    }
    
    func saveAllergiesRelations(type: SaveType, res: Place, allergies: [String]) {
        var resId = res.dbId
        let userAllergies = allergies.map() { item -> String in
            let key = Constants.allergens[item]
            return key!
        }
        var allergiesRef = self.restaurantsRef.child(res.dbId).child("allergies")
        if res.chainId != nil {
            resId = res.chainId!
            allergiesRef = self.ref.child("chain_restaurants").child(res.chainId!).child("allergies")
        }
        if type == .AddResAndPost {
            for item in userAllergies {
                let relation = [item: true]
                allergiesRef.updateChildValues(relation)
            }
        } else {
            allergiesRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
                if snapshot.exists() {
                    let data = snapshot.value as! [String: Bool]
                    let savedAllergies =  [String](data.keys)
                    for item in userAllergies {
                        if !savedAllergies.contains(item) {
                            let relation = [item: true]
                            allergiesRef.updateChildValues(relation)
                        }
                    }
                } else {
                    for item in userAllergies {
                        let relation = [item: true]
                        allergiesRef.updateChildValues(relation)
                    }
                }
            })
        }
        self.allergies = userAllergies
        let postId = self.ref.childByAutoId().key
        let ref = "postImages/\(postId).jpg"
        self.uploadImage(self.image!, ref: ref) { success, url in
            if success {
                self.savePost(url!, postId: postId, resId: resId)
            }
        }
    }
    
    func savePost(imageUrl: String, postId: String, resId: String) {
        if let user = FIRAuth.auth()?.currentUser {
            let timeStamp = self.timestamp
            print(user)
            var postData: [String: AnyObject] = ["id": postId, "created_at": timeStamp, "comment": self.comment, "userId": user.uid, "image": imageUrl, "resId": resId]
            postData["user"] = user.displayName ?? ""
            postData["userImage"] = user.photoURL?.absoluteString ?? ""
            self.savePostHelper(postId, ids: [user.uid, resId], data: postData)
            self.cleanup()
        }
    }
    
    func savePostHelper(postId: String, ids: [String], data: [String: AnyObject]) {
        for id in ids {
            let postRef = self.postsRef.child(id).child(postId)
            postRef.setValue(data)
            let allergiesRef = postRef.child("allergies")
            for item in self.allergies {
                allergiesRef.updateChildValues([item: true])
            }
        }
    }
    
    func uploadImage(image: UIImage, ref: String, completionHandler: (Bool, url: String?) -> ()) {
        let compressedImage = image.mediumQualityJPEGNSData
        let storage = FIRStorage.storage()
        let storageRef = storage.referenceForURL("gs://project-3482952858746148330.appspot.com")
        let imageRef = storageRef.child(ref)
        _ = imageRef.putData(compressedImage, metadata: nil) { metadata, error in
            if (error != nil) {
                // Uh-oh, an error occurred!
                completionHandler(false, url: nil)
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                completionHandler(true, url: (metadata!.downloadURL()?.absoluteString)!)
            }
        }
    }
    
    func cleanup() {
        self.image = nil
        self.commentId = ""
        self.place = nil
        self.allergies.removeAll()
        self.food = ""
        self.comment = ""
    }
    
}