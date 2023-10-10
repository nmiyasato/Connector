import Foundation
import Connector

class SampleViewModel {
    var loginConnector = LoginConnector()
    @Published var user: User?
    
    func getUser() async {
        let result = await loginConnector.user(id: "123", password: "something")
        
        switch result {
        case .success(let fetchedUser):
            self.user = fetchedUser
            print(self.user)
        case .failure(let error):
            print("Error fetching user: \(error)")
            // Handle the error accordingly
        }
    }
    // ... rest of the ViewModel
}
