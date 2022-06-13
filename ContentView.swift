//
//  ContentView.swift
//  ProjectiExpense
//
//  Created by Marko Zivanovic on 12.6.22..
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var expenses = Expenses()
    
    
    var body: some View {
        NavigationView {
            List {
                ForEach(expenses.items) { item in
                    Text(item.name)
                }
                .onDelete(perform: removeItems)
            }
            .navigationTitle("iExpenses")
            .toolbar {
                Button {
                    let expense = ExpenseItem(name: "name", type: "personal", amount: 5)
                    expenses.items.append(expense)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    func removeItems(at offsets: IndexSet) {
        expenses.items.remove(atOffsets: offsets)
        
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
