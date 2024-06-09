import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var profileImageUrl: String
}

struct UserListView: View {
    @State private var users = [User]()
    @State private var recentChats = [User]()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("AVAILABLE TO CHAT").font(.headline)) {
                    if users.isEmpty {
                        Text("No available users")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(users) { user in
                            NavigationLink(destination: ChatView(user: user)) {
                                UserRow(user: user)
                            }
                        }
                    }
                }
            }
            .onAppear(perform: fetchUsersAndChats)
            .navigationTitle("Chats")
        }
    }
    
    private func fetchUsersAndChats() {
        guard let currentUserEmail = FirebaseManager.shared.auth.currentUser?.email else { return }
        
        // Fetch all users
        FirebaseManager.shared.firestore.collection("users")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching users: \(error)")
                    return
                }
                let allUsers = snapshot?.documents.compactMap { document in
                    try? document.data(as: User.self)
                } ?? []
                
                // Filter out current user
                self.users = allUsers.filter { $0.email != currentUserEmail }
                
                // Fetch recent chats
                self.fetchRecentChats(allUsers: allUsers)
            }
    }
    
    private func fetchRecentChats(allUsers: [User]) {
        guard let currentUserEmail = FirebaseManager.shared.auth.currentUser?.email else { return }
        
        FirebaseManager.shared.firestore.collection("recentChats").document(currentUserEmail).collection("chats")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching recent chats: \(error)")
                    return
                }
                
                let recentChatEmails = snapshot?.documents.compactMap { document in
                    document.documentID
                } ?? []
                
                self.recentChats = allUsers.filter { user in
                    recentChatEmails.contains(user.email)
                }
                
                // Filter out recent chats from available users
                self.users.removeAll { user in
                    recentChatEmails.contains(user.email)
                }
                
                print("Recent chats fetched: \(self.recentChats.count)")
            }
    }
}

struct UserRow: View {
    var user: User
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: user.profileImageUrl)) { image in
                image.resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } placeholder: {
                ProgressView()
            }
            
            Text(user.email)
                .font(.headline)
        }
    }
}

#Preview {
    UserListView()
}

struct Chat: Codable {
    var participants: [String]
}
