import Foundation
import Connector

class SampleViewModel {
    var loginConnector = LoginConnector()
    @Published var user: User?
    
    func getUser() async {
        do {
            let fetchedUser = try await loginConnector.user(id: "123", password: "something")
            self.user = fetchedUser
            print(self.user)
        } catch {
            print("Error fetching user: \(error)")
            // Handle the error accordingly
        }
    }
    // ... rest of the ViewModel
}
