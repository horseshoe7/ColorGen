import Foundation


enum CodeBuildingError: Error {
    
}

protocol CodeBuilding {
    
    func build(_ colorList: [ColorGenColor], with name: String) throws
}
