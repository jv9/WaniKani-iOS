//
//  DataFetchManager.swift
//  
//
//  Created by Andriy K. on 8/19/15.
//
//

import UIKit
import WaniKit
import RealmSwift

class DataFetchManager: NSObject {
  
  static let sharedInstance = DataFetchManager()
  
  static let newStudyQueueReceivedNotification = "NewStudyQueueReceivedNotification"
  static let newLevelProgressionReceivedNotification = "NewLevelProgressionReceivedNotification"
  
  func performMigrationIfNeeded() {
    Realm.Configuration.defaultConfiguration = Realm.Configuration(
      schemaVersion: 1,
      migrationBlock: { migration, oldSchemaVersion in
//        if (oldSchemaVersion < 1) {
//          migration.enumerate(User.className()) { oldObject, newObject in
//            // combine name fields into a single field
//          }
//        }
    })
    _ = try! Realm()
  }
  
  func fetchAllData() {
    fetchStudyQueue({ () -> () in
      self.fetchLevelProgression()
      }, completionHandler: nil)
  }
  
  func fetchStudyQueue(handler: (() -> ())? ,completionHandler: ((result: UIBackgroundFetchResult)->())?) {
    do {
      try WaniApiManager.sharedInstance().fetchStudyQueue { (user, studyQ) -> () in
        
        var newNotification = false
        let realm = try! Realm()
        
        var realmUser: User
        if let currentUSer = realm.objects(User).first {
          realmUser = currentUSer
        } else {
          try! realm.write({ () -> Void in
            realm.add(user)
          })
          realmUser = user
        }
        
        try! realm.write({ () -> Void in
          realmUser.gravatar = user.gravatar
          realmUser.level = user.level
          realmUser.title = user.title
          realmUser.about = user.about
          realmUser.website = user.website
          realmUser.twitter = user.twitter
          realmUser.topicsCount = user.topicsCount
          realmUser.postsCount = user.postsCount
          realmUser.studyQueue = studyQ
          realm.add(realmUser, update: true)
        })
        realm.refresh()
        
        let users = realm.objects(User)
        print(users)
        if let user = users.first, let q = user.studyQueue {
          
          newNotification = NotificationManager.sharedInstance.scheduleNextReviewNotification(q.nextReviewDate)
          let newAppIconCounter = q.reviewsAvaliable + q.lessonsAvaliable
          let oldAppIconCounter = UIApplication.sharedApplication().applicationIconBadgeNumber
          newNotification = newNotification || (oldAppIconCounter != newAppIconCounter)
          UIApplication.sharedApplication().applicationIconBadgeNumber = newAppIconCounter
          NSNotificationCenter.defaultCenter().postNotificationName(DataFetchManager.newStudyQueueReceivedNotification, object: q)
        }
        if newNotification {
          completionHandler?(result: UIBackgroundFetchResult.NewData)
        } else {
          completionHandler?(result: UIBackgroundFetchResult.NoData)
        }
        handler?()
      }
    } catch  {
      completionHandler?(result: UIBackgroundFetchResult.Failed)
      handler?()
    }
  }
  
  func fetchLevelProgression() {
    do {
      try WaniApiManager.sharedInstance().fetchLevelProgression({ (user, levelProgression) -> () in
        let realm = try! Realm()
        
        var realmUser: User
        if let currentUSer = realm.objects(User).first {
          realmUser = currentUSer
        } else {
          try! realm.write({ () -> Void in
            realm.add(user)
          })
          realmUser = user
        }
        
        try! realm.write({ () -> Void in
          realmUser.gravatar = user.gravatar
          realmUser.level = user.level
          realmUser.title = user.title
          realmUser.about = user.about
          realmUser.website = user.website
          realmUser.twitter = user.twitter
          realmUser.topicsCount = user.topicsCount
          realmUser.postsCount = user.postsCount
          realmUser.levelProgression = levelProgression
          realm.add(realmUser, update: true)
        })
        realm.refresh()
        NSNotificationCenter.defaultCenter().postNotificationName(DataFetchManager.newLevelProgressionReceivedNotification, object: levelProgression)
      })
    } catch {
      
    }
    
  }
  
}
