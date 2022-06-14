DAY 37


* @Published publishes change announcements automatically.
* @StateObject watches for those announcements and refreshes any views using the object.
* sheet() watches a condition we specify and shows or hides a view automatically.
* Codable can convert Swift objects into JSON and back with almost no code from us.
* UserDefaults can read and write data so that we can save settings and more instantly.


Today you have five topics to work through, in which you’ll put into practice everything you learned about @StateObject, sheet(), onDelete(), and more.




Building a list we can delete from


In this project we want a list that can show some expenses, and previously we would have done this using an @State array of objects. Here, though, we’re going to take a different approach: we’re going to create an Expenses class that will be attached to our list using @StateObject.

This might sound like we’re over-complicating things a little, but it actually makes things much easier because we can make the Expenses class load and save itself seamlessly – it will be almost invisible, as you’ll see.

First, we need to decide what an expense is – what do we want it to store? In this instance it will be three things: the name of the item, whether it’s business or personal, and its cost as a Double.

We’ll add more to this later, but for now we can represent all that using a single ExpenseItem struct. You can put this into a new Swift file called ExpenseItem.swift, but you don’t need to – you can just put this into ContentView.swift if you like, as long as you don’t put it inside the ContentView struct itself.

Regardless of where you put it, this is the code to use:

struct ExpenseItem {
    let name: String
    let type: String
    let amount: Double
}

Now that we have something that represents a single expense, the next step is to create something to store an array of those expense items inside a single object. This needs to conform to the ObservableObject protocol, and we’re also going to use @Published to make sure change announcements get sent whenever the items array gets modified.

As with the ExpenseItem struct, this will start off simple and we’ll add to it later, so add this new class now:

class Expenses: ObservableObject {
    @Published var items = [ExpenseItem]()
}

That finishes all the data required for our main view: we have a struct to represent a single item of expense, and a class to store an array of all those items.

Let’s now put that into action with our SwiftUI view, so we can actually see our data on the screen. Most of our view will just be a List showing the items in our expenses, but because we want users to delete items they no longer want we can’t just use a simple List – we need to use a ForEach inside the list, so we get access to the onDelete() modifier.

First, we need to add an @StateObject property in our view, that will create an instance of our Expenses class:

@StateObject var expenses = Expenses()

Remember, using @StateObject here asks SwiftUI to watch the object for any change announcements, so any time one of our @Published properties changes the view will refresh its body. It’s only used when creating a class instance – all other times you ‘ll use @ObservedObject instead.

Second, we can use that Expenses object with a NavigationView, a List, and a ForEach, to create our basic layout:

NavigationView {
    List {
        ForEach(expenses.items, id: \.name) { item in
            Text(item.name)
        }
    }
    .navigationTitle("iExpense")
}

That tells the ForEach to identify each expense item uniquely by its name, then prints the name out as the list row.
We’re going to add two more things to our simple layout before we’re done: the ability to add new items for testing purposes, and the ability to delete items with a swipe.

We’re going to let users add their own items soon, but it’s important to check that our list actually works well before we continue. So, we’re going to add a toolbar button that adds example ExpenseItem instances for us to work with – add this modifier to the List now:

.toolbar {
    Button {
        let expense = ExpenseItem(name: "Test", type: "Personal", amount: 5)
        expenses.items.append(expense)
    } label: {
        Image(systemName: "plus")
    }
}


Now that we can add expenses, we can also add code to remove them. This means adding a method capable of deleting an IndexSet of list items, then passing that directly on to our expenses array:

func removeItems(at offsets: IndexSet) {
    expenses.items.remove(atOffsets: offsets)
}

And to attach that to SwiftUI, we add an onDelete() modifier to our ForEach, like this:

ForEach(expenses.items, id: \.name) { item in
    Text(item.name)
}
.onDelete(perform: removeItems)

Now, remember: when we say id: \.name we’re saying we can identify each item uniquely by its name, which isn’t true here – we have the same name multiple times, and we can’t guarantee our expenses will be unique either.




Working with Identifiable items in SwiftUI


When we create static views in SwiftUI – when we hard-code a VStack, then a TextField, then a Button, and so on – SwiftUI can see exactly which views we have, and is able to control them, animate them, and more. But when we use List or ForEach to make dynamic views, SwiftUI needs to know how it can identify each item uniquely otherwise it will struggle to compare view hierarchies to figure out what has changed.

In our current code, we have this:

ForEach(expenses.items, id: \.name) { item in
    Text(item.name)
}
.onDelete(perform: removeItems)

In English, that means “create a new row for every item in the expense items, identified uniquely by its name, showing that name in the row, and calling the removeItems() method to delete it.”

Then, later, we have this code:

Button {
    let expense = ExpenseItem(name: "Test", type: "Personal", amount: 5)
    expenses.items.append(expense)
} label: {
    Image(systemName: "plus")
}

Every time that button is pressed, it adds a test expense to our list, so we can make sure adding and deleting works.
Can you see the problem?

Every time we create an example expense item we’re using the name “Test”, but we’ve also told SwiftUI that it can use the expense name as a unique identifier. So, when our code runs and we delete an item, SwiftUI looks at the array beforehand – “Test”, “Test”, “Test”, “Test” – then looks at the array afterwards – “Test”, “Test”, “Test” – and can’t easily tell what changed. Something has changed, because one item has disappeared, but SwiftUI can’t be sure which.

In this situation we’re lucky, because List knows exactly which row we were swiping on, but in many other places that extra information won’t be available and our app will start to behave strangely.

This is a logic error on our behalf: our code is fine, and it doesn’t crash at runtime, but we’ve applied the wrong logic to get to that end result – we’ve told SwiftUI that something will be a unique identifier, when it isn’t unique at all.

To fix this we need to think more about our ExpenseItem struct. Right now it has three properties: name, type, and amount. The name by itself might be unique in practice, but it’s also likely not to be – as soon as the user enters “Lunch” twice we’ll start hitting problems. We could perhaps try to combine the name, type and amount into a new computed property, but even then we’re just delaying the inevitable; it’s still not really unique.

The smart solution here is to add something to ExpenseItem that is unique, such as an ID number that we assign by hand. That would work, but it does mean tracking the last number we assigned so we don’t use duplicates there either.
There is in fact an easier solution, and it’s called UUID – short for “universally unique identifier”, and if that doesn’t sound unique I’m not sure what does.

UUIDs are long hexadecimal strings such as this one: 08B15DB4-2F02-4AB8-A965-67A9C90D8A44. So, that’s eight digits, four digits, four digits, four digits, then twelve digits, of which the only requirement is that there’s a 4 in the first number of the third block. If we subtract the fixed 4, we end up with 31 digits, each of which can be one of 16 values – if we generated 1 UUID every second for a billion years, we might begin to have the slightest chance of generating a duplicate.

Now, we could update ExpenseItem to have a UUID property like this:

struct ExpenseItem {
    let id: UUID
    let name: String
    let type: String
    let amount: Int
}

And that would work. However, it would also mean we need to generate a UUID by hand, then load and save the UUID along with our other data. So, in this instance we’re going to ask Swift to generate a UUID automatically for us like this:

struct ExpenseItem {
    let id = UUID()
    let name: String
    let type: String
    let amount: Int
}

Now we don’t need to worry about the id value of our expense items – Swift will make sure they are always unique.
With that in place we can now fix our ForEach, like this:

ForEach(expenses.items, id: \.id) { item in
    Text(item.name)
}

If you run the app now you’ll see our problem is fixed: SwiftUI can now see exactly which expense item got deleted, and will animate everything correctly.

We’re not done with this step quite yet, though. Instead, I’d like you to modify the ExpenseItem to make it conform to a new protocol called Identifiable, like this:

struct ExpenseItem: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let amount: Int
}

All we’ve done is add Identifiable to the list of protocol conformances, nothing more. This is one of the protocols built into Swift, and means “this type can be identified uniquely.” It has only one requirement, which is that there must be a property called id that contains a unique identifier. We just added that, so we don’t need to do any extra work – our type conforms to Identifiable just fine.

Now, you might wonder why we added that, because our code was working fine before. Well, because our expense items are now guaranteed to be identifiable uniquely, we no longer need to tell ForEach which property to use for the identifier – it knows there will be an id property and that it will be unique, because that’s the point of the Identifiable protocol.

So, as a result of this change we can modify the ForEach again, to this:

ForEach(expenses.items) { item in
    Text(item.name)
}




Sharing an observed object with a new view



Classes that conform to ObservableObject can be used in more than one SwiftUI view, and all of those views will be updated when the published properties of the class change.
In this app, we’re going to design a view specially for adding new expense items. When the user is ready, we’ll add that to our Expenses class, which will automatically cause the original view to refresh its data so the expense item can be shown.


To make a new SwiftUI view you can either press Cmd+N.


As with our other views, our first pass at AddView will be simple and we’ll add to it. That means we’re going to add text fields for the expense name and amount, plus a picker for the type, all wrapped up in a form and a navigation view.
This should all be old news to you by now, so let’s get into the code:

struct AddView: View {
    @State private var name = ""
    @State private var type = "Personal"
    @State private var amount = 0.0

    let types = ["Business", "Personal"]

    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $name)

                Picker("Type", selection: $type) {
                    ForEach(types, id: \.self) {
                        Text($0)
                    }
                }

                TextField("Amount", value: $amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Add new expense")
        }
    }
}


Yes, that always uses US dollars for the currency type – you’ll need to make that smarter in the challenges for this project.
We’ll come back to the rest of that code in a moment, but first let’s add some code to ContentView so we can show AddView when the + button is tapped.

In order to present AddView as a new view, we need to make three changes to ContentView. First, we need some state to track whether or not AddView is being shown, so add this as a property now:

@State private var showingAddExpense = false

Next, we need to tell SwiftUI to use that Boolean as a condition for showing a sheet – a pop-up window. This is done by attaching the sheet() modifier somewhere to our view hierarchy. You can use the List if you want, but the NavigationView works just as well. Either way, add this code as a modifier to one of the views in ContentView:


.sheet(isPresented: $showingAddExpense) {
    // show an AddView here
}

The third step is to put something inside the sheet. Often that will just be an instance of the view type you want to show, like this:

.sheet(isPresented: $showingAddExpense) {
    AddView()
}

Here, though, we need something more. You see, we already have the expenses property in our content view, and inside AddView we’re going to be writing code to add expense items. We don’t want to create a second instance of the Expenses class in AddView, but instead want it to share the existing instance from ContentView.

So, what we’re going to do is add a property to AddView to store an Expenses object. It won’t create the object there, which means we need to use @ObservedObject rather than @StateObject.
Please add this property to AddView: which 

@ObservedObject var expenses: Expenses

And now we can pass our existing Expenses object from one view to another – they will both share the same object, and will both monitor it for changes. Modify your sheet() modifier in ContentView to this:

.sheet(isPresented: $showingAddExpense) {
    AddView(expenses: expenses)
}

We’re not quite done with this step yet, for two reasons: our code won’t compile, and even if it did compile it wouldn’t work because our button doesn’t trigger the sheet.

The compilation failure happens because when we made the new SwiftUI view, Xcode also added a preview provider so we can look at the design of the view while we were coding. If you find that down at the bottom of AddView.swift, you’ll see that it tries to create an AddView instance without providing a value for the expenses property.

That isn’t allowed any more, but we can just pass in a dummy value instead, like this:

struct AddView_Previews: PreviewProvider {
    static var previews: some View {
        AddView(expenses: Expenses())
    }
}

The second problem is that we don’t actually have any code to show the sheet, because right now the + button in ContentView adds test expenses. Fortunately, the fix is trivial – just replace the existing action with code to toggle our showingAddExpense Boolean, like this:

Button {
    showingAddExpense = true
} label: {
    Image(systemName: "plus")
}

If you run the app now the whole sheet should be working as intended – you start with ContentView, tap the + button to bring up an AddView where you can type in the various fields, then can swipe to dismiss.





