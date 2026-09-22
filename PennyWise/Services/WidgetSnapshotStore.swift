//
//  WidgetSnapshotStore.swift
//  PennyWise
//
//  Created by Devin Maleke on 22/09/26.
//

import Foundation
import WidgetKit

struct WidgetSnapshot: Codable, Equatable {
    var monthTitle: String
    var netText: String
    var spendText: String
    var incomeText: String
    var topExpenseName: String
    var topExpenseText: String
    var hasActivity: Bool
}

enum WidgetSnapshotStore {

    static let kind = "PennyWiseThisMonth"
    static let appGroupId = "group.com.custom.PennyWise"
    static let snapshotKey = "widget.snapshot"

    static func save(transactions: [TransactionModel]) {
        let calendar = Calendar.current
        let now = Date()
        let monthTransactions = transactions.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }

        let income = monthTransactions
            .filter { $0.category.type == .income }
            .reduce(0) { $0 + $1.amount }
        let spend = monthTransactions
            .filter { $0.category.type == .expense }
            .reduce(0) { $0 + $1.amount }
        let net = income - spend

        let topExpense = Dictionary(
            grouping: monthTransactions.filter { $0.category.type == .expense },
            by: { $0.category.name }
        )
        .map { name, list in (name, list.reduce(0) { $0 + $1.amount }) }
        .max { $0.1 < $1.1 }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")

        let snapshot = WidgetSnapshot(
            monthTitle: formatter.string(from: now),
            netText: net.asRupiah,
            spendText: spend.signedRupiah(isIncome: false),
            incomeText: income.signedRupiah(isIncome: true),
            topExpenseName: topExpense?.0 ?? "",
            topExpenseText: (topExpense?.1 ?? 0).asRupiah,
            hasActivity: !monthTransactions.isEmpty
        )

        persist(snapshot)
    }

    static func load() -> WidgetSnapshot? {
        guard
            let defaults = UserDefaults(suiteName: appGroupId),
            let data = defaults.data(forKey: snapshotKey)
        else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    static func clear() {
        UserDefaults(suiteName: appGroupId)?.removeObject(forKey: snapshotKey)
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }

    private static func persist(_ snapshot: WidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return }
        defaults.set(try? JSONEncoder().encode(snapshot), forKey: snapshotKey)
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
}
