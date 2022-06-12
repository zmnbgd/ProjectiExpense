//
//  Expenses.swift
//  ProjectiExpense
//
//  Created by Marko Zivanovic on 12.6.22..
//

import Foundation

class Expenses: ObservableObject {
    @Published var items = [ExpenseItem]()
}
