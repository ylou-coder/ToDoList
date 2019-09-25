//
//  ToDoItem.swift
//  Programmatic-UI-Boilerplate
//
//  Created by Laurie Ou on 9/24/19.
//  Copyright © 2019 Matt Oaxaca. All rights reserved.
//

struct ToDoItem {
    var id: String
    var text: String
    var userID: String
    var isCompleted = false
    
    func getDict() -> [String:Any] {
        let dict = ["id": self.id,
                     "text": self.text,
                     "userID": self.userID,
                     "isCompleted": self.isCompleted,
            ] as [String : Any]

          return dict
    }
}
