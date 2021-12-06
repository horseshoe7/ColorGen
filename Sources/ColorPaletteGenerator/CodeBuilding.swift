//
//  File.swift
//  
//
//  Created by Stephen OConnor on 01.12.21.
//

import Foundation


enum CodeBuildingError: Error {
    
}

protocol CodeBuilding {
    
    func build(_ colorList: [ColorGenColor], with name: String) throws
}
