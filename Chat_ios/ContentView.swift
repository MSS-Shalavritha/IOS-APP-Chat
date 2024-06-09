import SwiftUI

struct ContentView: View {
    var body: some View {
        if FirebaseManager.shared.auth.currentUser != nil {
            UserListView()
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
}
