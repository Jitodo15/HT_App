//
//  LoginView.swift
//  HT_App
//
//  Created by Joy Itodo on 1/29/25.
//

import Foundation
import SwiftUI
import CryptoKit
@preconcurrency import PostgresNIO

struct LoginView: View {
    @State var username: String = ""
    @State var password: String = ""
    @State var isPasswordVisible: Bool = false
    @State var isLoginSuccessful: Bool? = nil
    @State var errorMessage: String? = nil
    @State var showAlert: Bool = false
    @State var alertMessage: String = ""

    
    func hashPassword(password: String) -> String {
        let passwordData = Data(password.utf8)
        let hashed = SHA256.hash(data: passwordData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
        
    func login(username: String, password: String) async -> Bool {
        guard let connection = DatabaseManager.shared.getConnection() else {
            print("❌ No active database connection")
            return false
        }

        let hashedPassword = hashPassword(password: password)
        let sql = "SELECT id, username, password FROM users WHERE username = $1"
        let usernameData = PostgresData(string: username)

        do {
            let result = try await connection.query(sql, [usernameData]).get()
            if let row = result.first?.makeRandomAccess(), let storedPasswordHash = row[data:"password"].string {
                if storedPasswordHash == hashedPassword {
                    alertMessage = "✅ Login successful"
                    showAlert = true
                    clearFields()
                    return true
                } else {
                    alertMessage = "❌ Incorrect password"
                    showAlert = true
                    return false
                }
            } else {
                alertMessage = "❌ Username not found"
                showAlert = true
                return false
            }
        } catch {
            print("❌ Error during login: \(error)")
            return false
        }
    }
    
    func clearFields() {
        username = ""
        password = ""
    }
    
    var body: some View {
        NavigationView {
            VStack{
                Text("Welcome Back!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 42)
                VStack(spacing: 14.0){
                    TextField("Username", text: $username)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    HStack {
                        if isPasswordVisible {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                        Button(action: {isPasswordVisible.toggle()}) {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }.padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.bottom, 22)
                Button(action: {
                    Task {
                        let isSuccess = await login(username: username, password: password)
                        await MainActor.run {
                            if isSuccess {
                                isLoginSuccessful = true
                                errorMessage = nil
                            } else {
                                isLoginSuccessful = false
                                errorMessage = "Incorrect username or password."
                            }
                        }
                    }
                }) {
                    Text("Log In")
                        .fontWeight(.heavy)
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(Color.white)
                        .background(Color(red: 90/255, green: 0/255, blue: 0/255))
                        .cornerRadius(10)
                }
                .disabled(username.isEmpty || password.isEmpty)
                
                HStack{
                    NavigationLink(destination: SignupView()) {
                        Text("Don't have an account? Sign Up")
                            .fontWeight(.thin)
                            .foregroundColor(.blue)
                            .underline()
                    }
                    Spacer()
                    Text("Forgot Password?")
                        .fontWeight(.thin)
                        .foregroundStyle(Color.blue)
                        .underline()
                }.padding(.top, 16)
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Login Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
//            .alert(isPresented: Binding<Bool>(
//                get: { isLoginSuccessful ?? false },
//                set: { isLoginSuccessful = $0 ? true : nil }
//            )) {
//                Alert(title: Text("Login Success"), message: Text("You are now logged in!"), dismissButton: .default(Text("OK")))
//            }
        }
    }
}

#Preview {
    LoginView()
}
