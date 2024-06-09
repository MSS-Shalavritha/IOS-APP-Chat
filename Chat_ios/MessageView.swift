import SwiftUI
import FirebaseFirestoreSwift

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    let userUid: String
    let text: String
    let photoURL: String
    let createdAt: Date
    
    func isFromCurrentUser() -> Bool {
        return userUid == FirebaseManager.shared.auth.currentUser?.uid
    }
}

struct MessageView: View {
    var message: Message
    
    var body: some View {
        if message.isFromCurrentUser() {
            HStack {
                Spacer()
                HStack {
                    Text(message.text).padding()
                }
                .frame(maxWidth: 260, alignment: .topLeading)
                .background(Color.blue)
                .cornerRadius(20)
                
                if let photoURL = URL(string: message.photoURL), let imageData = try? Data(contentsOf: photoURL), let profileImage = UIImage(data: imageData) {
                    Image(uiImage: profileImage)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person")
                        .frame(maxHeight: 32, alignment: .top)
                        .padding(.bottom, 16)
                        .padding(.leading, 4)
                }
            }
            .frame(maxWidth: 360, alignment: .trailing)
        } else {
            HStack {
                if let photoURL = URL(string: message.photoURL), let imageData = try? Data(contentsOf: photoURL), let profileImage = UIImage(data: imageData) {
                    Image(uiImage: profileImage)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person")
                        .frame(maxHeight: 32, alignment: .top)
                        .padding(.bottom, 16)
                        .padding(.trailing, 4)
                }
                
                HStack {
                    Text(message.text).padding()
                }
                .frame(maxWidth: 260, alignment: .leading)
                .background(Color.gray)
                .cornerRadius(20)
            }
            .frame(maxWidth: 360, alignment: .leading)
        }
    }
}


struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(message: Message(userUid: "123", text: "This is a test message", photoURL: "", createdAt: Date()))
    }
}
