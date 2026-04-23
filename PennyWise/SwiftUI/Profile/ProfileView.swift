//
//  ProfileView.swift
//  PennyWise
//
//  Created by Samir iOS on 05/02/26.
//

import SwiftUI

struct ProfileView: View {

    @StateObject private var viewModel = ProfileViewModel()

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false

    var body: some View {
        NavigationView {
            ZStack{
                AppBackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    HStack{
                        Text("Update Name")
                            .font(.headline)
                            .bold()
                        
                        Spacer()
                    }
                    
                    // MARK: - Basic Info
                    VStack(alignment: .leading, spacing: 12) {
                        inputField(title: "Name", text: $viewModel.name)
                        inputField(title: "Email", text: .constant(viewModel.email), backgroundColor: Color(.systemGray5))
                            .disabled(true)
                        
                            .padding(.bottom,24)
                        Button {
                            viewModel.updateName()
                        } label: {
                            Text("Save Name")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "1D2E3E"))
                                .foregroundColor(Color(hex: "F9F9FC"))
                                .cornerRadius(12)
                        }
                        .disabled(!viewModel.isNameChanged)
                        .opacity(viewModel.isNameChanged ? 1 : 0.5)
                        
                        
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 0.5)
                    
                    
                    HStack{
                        Text("Update Password")
                            .font(.headline)
                            .bold()
                        
                        Spacer()
                    }
                    // MARK: - Change Password
                    VStack(alignment: .leading, spacing: 12) {
                        
                        secureInputField(
                            title: "Current Password",
                            text: $currentPassword,
                            isVisible: $showCurrentPassword
                        )
                        
                        secureInputField(
                            title: "New Password",
                            text: $newPassword,
                            isVisible: $showNewPassword
                        )
                        .padding(.bottom,24)
                        
                        Button {
                            viewModel.changePassword(
                                currentPassword: currentPassword,
                                newPassword: newPassword
                            )
                            currentPassword = ""
                            newPassword = ""
                        } label: {
                            Text("Update Password")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "1D2E3E"))
                                .foregroundColor(Color(hex: "F9F9FC"))
                                .cornerRadius(12)
                        }
                        .disabled(newPassword.count < 6)
                        .opacity(newPassword.count > 6 ? 1 : 0.5)
                        
                        
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 0.5)
                    
                    // MARK: - Feedback
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                    }
                    
                    if let success = viewModel.successMessage {
                        Text(success)
                            .foregroundColor(.green)
                    }
                }

                
                Divider()
                    .padding(.vertical, 8)

                Button {
                    viewModel.logout()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Logout")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemRed).opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                }
                
                
            }
            .padding()
        }

            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: viewModel.successMessage) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                viewModel.successMessage = nil
            }
            viewModel.fetchProfile()
        }
        .onChange(of: viewModel.name) { _ in
            viewModel.errorMessage = nil
        }

    }
}

