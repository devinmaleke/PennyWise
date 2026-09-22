//
//  UserStore.swift
//  PennyWise
//
//  Created by Devin Maleke on 24/02/26.
//

import Combine
import FirebaseAuth
import FirebaseFirestore

final class UserStore: ObservableObject {

    static let shared = UserStore() // boleh singleton kalau root UIKit

    @Published private(set) var user: UserModel?

    private var listener: ListenerRegistration?

    func start() {
        stop()
        guard let uid = Auth.auth().currentUser?.uid else { return }

        listener = Firestore.firestore()
            .collection("users")
            .document(uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let data = snapshot?.data() else { return }

                let user = UserModel(
                    id: uid,
                    name: data["name"] as? String ?? "",
                    email: data["email"] as? String ?? ""
                )

                DispatchQueue.main.async {
                    self?.user = user
                }
            }
    }

    func stop() {
        listener?.remove()
        listener = nil
        user = nil
    }
}
