//
//  ProfileView.swift
//  PennyWise
//
//  Created by Devin Maleke on 05/02/26.
//

import SwiftUI

struct ProfileView: View {

    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject private var appLock = AppLockService.shared
    @ObservedObject private var appearance = AppearanceStore.shared

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationView {
            ZStack{
                AppBackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    HStack{
                        Text("Privacy")
                            .font(.headline)
                            .bold()
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: appLockBinding) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Lock with \(appLock.biometryName)")
                                    .bold()
                                    .foregroundColor(Color.appInk)
                                Text("Ask for \(appLock.biometryName) when opening PennyWise")
                                    .font(.caption)
                                    .foregroundColor(Color.appMuted)
                            }
                        }
                        .disabled(!appLock.canUseLock && !appLock.isEnabled)
                    }
                    .padding()
                    .background(Color.appCard)
                    .cornerRadius(8)
                    .shadow(radius: 0.5)
                    .padding(.horizontal,2)

                    HStack{
                        Text("Appearance")
                            .font(.headline)
                            .bold()
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Theme")
                            .bold()
                            .foregroundColor(Color.appInk)
                        Picker("Theme", selection: $appearance.mode) {
                            ForEach(AppearanceMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding()
                    .background(Color.appCard)
                    .cornerRadius(8)
                    .shadow(radius: 0.5)
                    .padding(.horizontal,2)

                    HStack{
                        Text("Recurring")
                            .font(.headline)
                            .bold()
                        Spacer()
                    }

                    NavigationLink(destination: RecurringListView()
                        .navigationBarBackButtonHidden(true)) {
                        HStack {
                            Image(systemName: "repeat")
                            Text("Manage rent, salary, and bills")
                                .bold()
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color.appMuted)
                        }
                        .foregroundColor(Color.appInk)
                        .padding()
                        .background(Color.appCard)
                        .cornerRadius(8)
                        .shadow(radius: 0.5)
                        .padding(.horizontal,2)
                    }

                    HStack{
                        Text("Export")
                            .font(.headline)
                            .bold()
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Period")
                                .bold()
                                .foregroundColor(Color.appInk)

                            Spacer()

                            Menu {
                                ForEach(ExportPeriod.allCases) { period in
                                    Button {
                                        viewModel.exportPeriod = period
                                    } label: {
                                        HStack {
                                            Text(period.rawValue)
                                            if viewModel.exportPeriod == period {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(viewModel.exportPeriod.rawValue)
                                        .font(.subheadline)
                                        .foregroundColor(Color.appInk)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(Color.appMuted)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.appFill)
                                .cornerRadius(8)
                            }
                        }

                        Text("Share a spreadsheet of date, title, category, note, and amount")
                            .font(.caption)
                            .foregroundColor(Color.appMuted)

                        Button {
                            viewModel.exportCSV()
                        } label: {
                            HStack {
                                if viewModel.isExporting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color.appOnAccent))
                                }
                                Text("Export CSV")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appAccent)
                            .foregroundColor(Color.appOnAccent)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isExporting)
                        .opacity(viewModel.isExporting ? 0.5 : 1)
                    }
                    .padding()
                    .background(Color.appCard)
                    .cornerRadius(8)
                    .shadow(radius: 0.5)
                    .padding(.horizontal,2)

                    HStack{
                        Text("Update Name")
                            .font(.headline)
                            .bold()
                        
                        Spacer()
                    }
                    
                    // MARK: - Basic Info
                    VStack(alignment: .leading, spacing: 12) {
                        inputField(title: "Name", text: $viewModel.name)
                        inputField(title: "Email", text: .constant(viewModel.email), backgroundColor: Color.appFill)
                            .disabled(true)
                        
                            .padding(.bottom,24)
                        Button {
                            viewModel.updateName()
                        } label: {
                            Text("Save Name")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.appAccent)
                                .foregroundColor(Color.appOnAccent)
                                .cornerRadius(12)
                        }
                        .disabled(!viewModel.isNameChanged)
                        .opacity(viewModel.isNameChanged ? 1 : 0.5)
                        
                        
                    }
                    .padding()
                    .background(Color.appCard)
                    .cornerRadius(8)
                    .shadow(radius: 0.5)
                    .padding(.horizontal,2)
                    
                    
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
                            ) { success in
                                if success {
                                    currentPassword = ""
                                    newPassword = ""
                                }
                            }
                        } label: {
                            Text("Update Password")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.appAccent)
                                .foregroundColor(Color.appOnAccent)
                                .cornerRadius(12)
                        }
                        .disabled(currentPassword.isEmpty || newPassword.count < 6)
                        .opacity(currentPassword.isEmpty || newPassword.count < 6 ? 0.5 : 1)
                        
                        
                    }
                    .padding()
                    .background(Color.appCard)
                    .cornerRadius(8)
                    .shadow(radius: 0.5)
                    .padding(.horizontal,2)
                    
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
                    showLogoutConfirm = true
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
            .confirmationDialog(
                "Logout",
                isPresented: $showLogoutConfirm,
                titleVisibility: .visible
            ) {
                Button("Logout", role: .destructive) {
                    viewModel.logout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You will need to sign in again to see your transactions.")
            }
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

    private var appLockBinding: Binding<Bool> {
        Binding(
            get: { appLock.isEnabled },
            set: { viewModel.setAppLock($0) }
        )
    }
}

