//
//  SignupView.swift
//  HT_App
//
//  Created by Joy Itodo on 1/31/25.
//

import Foundation
import SwiftUI
import CryptoKit
import PostgresNIO

struct SignupView: View {
    @State var fullName: String = ""
    @State var email: String = ""
    @State var username: String = ""
    @State var password: String = ""
    @State var confirmPassword: String = ""
    @State var isPasswordVisible: Bool = false
    @State var isConfirmPasswordVisible: Bool = false
    @State var isSignupSuccess: Bool = false
    
    func hashPassword(password: String) -> String {
        let passwordData = Data(password.utf8)
        let hashed = SHA256.hash(data: passwordData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
    
    func signup() {
        if password != confirmPassword {
            print("Passwords don't match.")
            return
        }
            
        let hashedPassword = hashPassword(password: password)
            
        Task {
            await insertUserToDatabase(fullName: fullName, email: email, username: username, passwordHash: hashedPassword)
        }
    }
        
    func insertUserToDatabase(fullName: String, email: String, username: String, passwordHash: String) async {
        guard let connection = DatabaseManager.shared.getConnection() else {
            print("❌ No active database connection")
            return
        }
            
        let sql = """
        INSERT INTO users (full_name, email, username, password, created_at)
        VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP);
        """
        let parameters: [PostgresData] = [
            PostgresData(string: fullName),
            PostgresData(string: email),
            PostgresData(string: username),
            PostgresData(string: passwordHash)
        ]
        
        do {
            try await connection.query(sql, parameters)
            print("✅ User inserted successfully!")
            isSignupSuccess = true
            clearFields()
        } catch {
            print("❌ Error inserting user: \(error)")
        }
    }
    
    func clearFields() {
        fullName = ""
        email = ""
        username = ""
        password = ""
        confirmPassword = ""
    }
    
    var body: some View {
        NavigationView{
            VStack{
                Text("Get Started")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 42)
                VStack(spacing: 10.0){
                    TextField("Full Name", text: $fullName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    TextField("Email Adress", text: $email)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
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
                    HStack {
                        if isConfirmPasswordVisible {
                            TextField("Confirm Password", text: $confirmPassword)
                        } else {
                            SecureField("Confirm Password", text: $confirmPassword)
                        }
                        Button(action: {isConfirmPasswordVisible.toggle()}) {
                            Image(systemName: isConfirmPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }.padding()
                     .background(Color(.systemGray6))
                     .cornerRadius(10)
                }
                .padding(.bottom, 22)
                
                Button(action: signup){
                    Text("Sign Up")
                        .fontWeight(.heavy)
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(Color.white)
                        .background(Color(red: 90/255, green: 0/255, blue: 0/255))
                        .cornerRadius(10)
                }
                .disabled(fullName.isEmpty || email.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                HStack{
                    NavigationLink(destination: LoginView()) {
                        Text("Already have an account? Log In")
                            .fontWeight(.thin)
                            .foregroundStyle(Color.blue)
                            .underline()
                    }
                    Spacer()
                    
                }.padding(.top, 16)
                
            }
            .padding()
            
        }
    }
    
}
#Preview {
    SignupView()
}
