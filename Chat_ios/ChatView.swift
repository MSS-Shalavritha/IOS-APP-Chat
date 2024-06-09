import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ChatView: View {
    let user: User
    @State private var messageText = ""
    @State private var messages = [Message]()
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach(messages) { message in
                    MessageView(message: message)
                }
            }
            
            HStack {
                TextField("Enter message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 30)
                
                Button(action: sendMessage) {
                    Text("Send")
                }
            }
            .padding()
        }
        .navigationTitle(user.email)
        .onAppear(perform: fetchMessages)
    }
    
    private func sendMessage() {
        guard let currentUserUID = FirebaseManager.shared.auth.currentUser?.uid, let otherUserUID = user.id, let currentUserEmail = FirebaseManager.shared.auth.currentUser?.email else { return }
        
        let chatId = generateChatId(currentUserUID: currentUserUID, otherUserUID: otherUserUID)
        
        let newMessage = Message(userUid: currentUserUID, text: messageText, photoURL: "", createdAt: Date())
        
        do {
            _ = try FirebaseManager.shared.firestore.collection("chats").document(chatId).collection("messages").addDocument(from: newMessage) { error in
                if let error = error {
                    print("Error sending message: \(error)")
                } else {
                    print("Message sent successfully")
                    self.messageText = ""
                    updateRecentChats(otherUserUID: otherUserUID)
                }
            }
        } catch {
            print("Error encoding message: \(error)")
        }
    }

    private func updateRecentChats(otherUserUID: String) {
        guard let currentUserUID = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let currentUserRef = FirebaseManager.shared.firestore.collection("recentChats").document(currentUserUID).collection("chats").document(otherUserUID)
        let otherUserRef = FirebaseManager.shared.firestore.collection("recentChats").document(otherUserUID).collection("chats").document(currentUserUID)
        
        let userData = ["email": user.email, "profileImageUrl": user.profileImageUrl]
        let currentUserData = ["email": FirebaseManager.shared.auth.currentUser?.email ?? "", "profileImageUrl": ""]
        
        currentUserRef.setData(userData)
        otherUserRef.setData(currentUserData)
    }

    
    private func fetchMessages() {
        guard let currentUserUID = FirebaseManager.shared.auth.currentUser?.uid, let otherUserUID = user.id else { return }
        
        let chatId = generateChatId(currentUserUID: currentUserUID, otherUserUID: otherUserUID)
        
        FirebaseManager.shared.firestore.collection("chats").document(chatId).collection("messages")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("No documents")
                    return
                }
                
                self.messages = documents.compactMap { document -> Message? in
                    do {
                        return try document.data(as: Message.self)
                    } catch {
                        print("Error decoding message: \(error)")
                        return nil
                    }
                }
            }
    }
    
    private func generateChatId(currentUserUID: String, otherUserUID: String) -> String {
        return currentUserUID < otherUserUID ? "\(currentUserUID)_\(otherUserUID)" : "\(otherUserUID)_\(currentUserUID)"
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(user: User(id: "test", email: "test@example.com", profileImageUrl: ""))
    }
}
