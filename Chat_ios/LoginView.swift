import SwiftUI

struct LoginView: View {
    @State var isLoginMode = false
    @State var email = ""
    @State var password = ""
    @State var selectedImage: UIImage?
    @State var shouldShowImagePicker = false
    @State var loginStatusMessage = ""
    @State var shouldNavigateToUserList = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Picker(selection: $isLoginMode, label: Text("Picker here")) {
                        Text("Login").tag(true)
                        Text("Create New Account").tag(false)
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    if !isLoginMode {
                        Button {
                            shouldShowImagePicker.toggle()
                        } label: {
                            VStack {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 64)
                                        .clipped()
                                        .cornerRadius(32)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .padding()
                                }
                            }
                        }
                    }
                    
                    Group {
                        TextField("Email", text: $email).keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                    }.padding(12)
                        .background(Color.white)
                    
                    Button {
                        handleFunc()
                    } label: {
                        HStack {
                            Spacer()
                            Text(isLoginMode ? "Login" : "Create Account").foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }.background(Color.blue)
                    }
                    
                    Text(self.loginStatusMessage).foregroundColor(.red)
                }
                .padding()
            }
            .navigationTitle(isLoginMode ? "Log In" : "Create Account")
            .background(Color(.init(white: 0, alpha: 0.05)).ignoresSafeArea())
            .sheet(isPresented: $shouldShowImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .navigationDestination(isPresented: $shouldNavigateToUserList) {
                UserListView()
            }
        }
    }
    
    private func handleFunc() {
        if isLoginMode {
            loginUser()
        } else {
            createNewAccount()
        }
    }
    
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, err in
            if let err = err {
                print("Failed to login user:", err)
                self.loginStatusMessage = "Failed to login user: \(err)"
                return
            }
            print("Successfully logged in as user: \(result?.user.uid ?? "")")
            self.loginStatusMessage = "Successfully logged in as user: \(result?.user.uid ?? "")"
            self.shouldNavigateToUserList = true
        }
    }
    
    private func createNewAccount() {
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, err in
            if let err = err {
                print("Failed to create user:", err)
                self.loginStatusMessage = "Failed to create user: \(err)"
                return
            }
            print("Successfully created user: \(result?.user.uid ?? "")")
            self.loginStatusMessage = "Successfully created user: \(result?.user.uid ?? "")"
            self.persistImageToStorage()
        }
    }
    
    private func persistImageToStorage() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.selectedImage?.jpegData(compressionQuality: 0.5) else { return }
        
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                print("Failed to upload image:", err)
                self.loginStatusMessage = "Failed to upload image: \(err)"
                return
            }
            ref.downloadURL { url, err in
                if let err = err {
                    print("Failed to retrieve download URL:", err)
                    self.loginStatusMessage = "Failed to retrieve download URL: \(err)"
                    return
                }
                print("Successfully stored image with url:", url?.absoluteString ?? "")
                self.loginStatusMessage = "Successfully stored image with url: \(url?.absoluteString ?? "")"
                self.storeUserInformation(imageURL: url)
            }
        }
    }
    
    private func storeUserInformation(imageURL: URL?) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let userData = ["email": self.email, "uid": uid, "profileImageUrl": imageURL?.absoluteString ?? ""]
        
        FirebaseManager.shared.firestore.collection("users").document(uid).setData(userData) { err in
            if let err = err {
                print("Failed to store user information:", err)
                self.loginStatusMessage = "Failed to store user information: \(err)"
                return
            }
            print("Successfully stored user information")
            self.shouldNavigateToUserList = true
        }
    }
}

#Preview {
    LoginView()
}
