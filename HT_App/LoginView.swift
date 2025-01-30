//
//  LoginView.swift
//  HT_App
//
//  Created by Joy Itodo on 1/29/25.
//

import Foundation
import SwiftUI

struct LoginView: View {
    @State var username: String = ""
    @State var password: String = ""
    @State var isPasswordVisible: Bool = false
    
    var body: some View {
        VStack{
            Text("Welcome Back")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 42)
            VStack(spacing: 16.0){
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
            Button(action: {}){
                Text("Log In")
                    .fontWeight(.heavy)
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(Color.white)
                    .background(Color.black)
                    .cornerRadius(10)
            }
            HStack{
                Text("Don't have an account? Sign Up")
                    .fontWeight(.thin)
                    .foregroundStyle(Color.blue)
                    .underline()
                Spacer()
                Text("Forgot Password?")
                    .fontWeight(.thin)
                    .foregroundStyle(Color.blue)
                    .underline()
            }.padding(.top, 16)
            
        }
        .padding()
    }
}

#Preview {
    LoginView()
}
