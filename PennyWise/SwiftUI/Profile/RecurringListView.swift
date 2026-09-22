//
//  RecurringListView.swift
//  PennyWise
//
//  Created by Devin Maleke on 21/09/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RecurringListView: View {

    @StateObject private var viewModel = RecurringListViewModel()
    @State private var templateToEdit: RecurringTemplate?
    @State private var templatePendingDelete: RecurringTemplate?
    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppBackgroundView()
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.templates.isEmpty {
                        EmptyStateView(
                            icon: "repeat",
                            title: "No recurring transactions",
                            message: "Turn on Repeat when adding a transaction, like rent or salary."
                        )
                        .background(Color.appCard)
                        .cornerRadius(8)
                        .shadow(radius: 0.5)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.templates) { template in
                                RecurringRow(
                                    template: template,
                                    onToggle: { isActive in
                                        viewModel.setActive(template, isActive: isActive)
                                    }
                                )
                                .onTapGesture {
                                    templateToEdit = template
                                }
                                .contextMenu {
                                    Button("Edit") {
                                        templateToEdit = template
                                    }
                                    Button("Delete", role: .destructive) {
                                        templatePendingDelete = template
                                        showDeleteConfirm = true
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Recurring")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.appInk)
                }
            }
        }
        .sheet(item: $templateToEdit) { template in
            RecurringEditView(
                isPresented: Binding(
                    get: { templateToEdit != nil },
                    set: { if !$0 { templateToEdit = nil } }
                ),
                template: template
            )
        }
        .alert(isPresented: errorAlertBinding) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? AppErrorMapper.genericMessage),
                dismissButton: .default(Text("OK")) {
                    viewModel.errorMessage = nil
                }
            )
        }
        .confirmationDialog(
            "Delete Recurring",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let template = templatePendingDelete {
                    viewModel.delete(template)
                }
                templatePendingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                templatePendingDelete = nil
            }
        } message: {
            Text("Existing transactions stay. Future repeats will stop.")
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

private struct RecurringRow: View {

    let template: RecurringTemplate
    var onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: template.category.colorHex).opacity(0.15))
                    .frame(width: 36, height: 36)
                Circle()
                    .fill(Color(hex: template.category.colorHex))
                    .frame(width: 10, height: 10)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(template.title)
                    .bold()
                    .foregroundColor(Color.appInk)

                Text("\(template.frequency.title) · \(template.category.name)")
                    .font(.caption)
                    .foregroundColor(Color.appMuted)

                if template.isActive {
                    Text("Next \(template.nextDate.formatted())")
                        .font(.caption2)
                        .foregroundColor(Color.appMuted)
                } else {
                    Text("Paused")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "E74C3C"))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text(
                    template.amount.signedRupiah(isIncome: template.isIncome)
                )
                .font(.subheadline)
                .bold()
                .foregroundColor(
                    template.isIncome ? Color(hex: "27AE60") : Color(hex: "E74C3C")
                )

                Toggle("", isOn: Binding(
                    get: { template.isActive },
                    set: onToggle
                ))
                .labelsHidden()
            }
        }
        .padding()
        .background(Color.appCard)
        .cornerRadius(8)
        .shadow(radius: 0.5)
        .opacity(template.isActive ? 1 : 0.7)
    }
}

final class RecurringListViewModel: ObservableObject {

    @Published var templates: [RecurringTemplate] = []
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?

    init() {
        startListening()
    }

    deinit {
        listener?.remove()
    }

    func setActive(_ template: RecurringTemplate, isActive: Bool) {
        RecurringService.setActive(template, isActive: isActive) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = AppErrorMapper.message(for: error)
                }
            }
        }
    }

    func delete(_ template: RecurringTemplate) {
        RecurringService.delete(id: template.id) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = AppErrorMapper.message(for: error)
                }
            }
        }
    }

    private func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        listener = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("recurring")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = AppErrorMapper.message(for: error)
                    }
                    return
                }

                let parsed = snapshot?.documents.compactMap(RecurringTemplate.from) ?? []
                DispatchQueue.main.async {
                    self?.templates = parsed.sorted {
                        $0.nextDate < $1.nextDate
                    }
                }
            }
    }
}
