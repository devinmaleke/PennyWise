//
//  AddCategoryView.swift
//  PennyWise
//
//  Created by Samir iOS on 02/02/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AddCategoryView: View {

    @Binding var isPresented: Bool
    var onSave: () -> Void

    @State private var name = ""
    @State private var type: CategoryType = .expense

    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                inputField(
                    title: "Category Name",
                    text: $name,
                    keyboard: .default
                )
                
                HStack{
                    Text("Category Type")
                        .bold()
                        .foregroundColor(Color(hex: "1D2E3E"))
                    Spacer()
                }
                
                Picker("Type", selection: $type) {
                    Text("Expense").tag(CategoryType.expense)
                    Text("Income").tag(CategoryType.income)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Spacer()
                
                Button {
                    saveCategory()
                } label: {
                    HStack {
                        Text("Save")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "1D2E3E"))
                    .foregroundColor(Color(hex: "F9F9FC"))
                    .cornerRadius(14)
                }
                .disabled(name.isEmpty)
                .opacity(name.isEmpty ? 0.5 : 1)

                
            }
            .padding()
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isPresented = false } label: { Text("Close") .foregroundColor(.black) }
                }
            }
        }
    }

    private func saveCategory() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users")
            .document(uid)
            .collection("categories")
            .addDocument(data: [
                "name": name,
                "type": type.rawValue,
                "colorHex": "#1D2E3E",
                "createdAt": Timestamp()
            ]) { _ in
                onSave()
                isPresented = false
            }
    }
}


