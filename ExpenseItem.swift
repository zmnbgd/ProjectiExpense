//
//  ExpenseItem.swift
//  ProjectiExpense
//
//  Created by Marko Zivanovic on 12.6.22..
//

import Foundation

struct ExpenseItem: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let amount: Double
}
