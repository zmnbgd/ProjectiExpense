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





Making changes permanent with UserDefaults




At this point, our app’s user interface is functional: you’ve seen we can add and delete items, and now we have a sheet showing a user interface to create new expenses. However, the app is far from working: any data placed into AddView is completely ignored, and even if it weren’t ignored then it still wouldn’t be saved for future times the app is run.

We’ll tackle those problems in order, starting with actually doing something with the data from AddView. We already have properties that store the values from our form, and previously we added a property to store an Expenses object passed in from the ContentView.

We need to put those two things together: we need a button that, when tapped, creates an ExpenseItem out of our properties and adds it to the expenses items.

Add this modifier below navigationTitle() in AddView:

.toolbar {
    Button("Save") {
        let item = ExpenseItem(name: name, type: type, amount: amount)
        expenses.items.append(item)
    }
}

Although we have more work to do, I encourage you to run the app now because it’s actually coming together – you can now show the add view, enter some details, press “Save”, then swipe to dismiss, and you’ll see your new item in the list. That means our data synchronization is working perfectly: both the SwiftUI views are reading from the same list of expense items.

Now try launching the app again, and you’ll immediately hit our second problem: any data you add isn’t stored, meaning that everything starts blank every time you relaunch the app.

This is obviously a pretty terrible user experience, but thanks to the way we have Expense as a separate class it’s actually not that hard to fix.

We’re going to leverage four important technologies to help us save and load data in a clean way:

* The Codable protocol, which will allow us to archive all the existing expense items ready to be stored.
* UserDefaults, which will let us save and load that archived data.
* A custom initializer for the Expenses class, so that when we make an instance of it we load any saved data from UserDefaults
* A didSet property observer on the items property of Expenses, so that whenever an item gets added or removed we’ll write out changes.


Let’s tackle writing the data first. We already have this property in the Expenses class:

@Published var items = [ExpenseItem]()

That’s where we store all the expense item structs that have been created, and that’s also where we’re going to attach our property observer to write out changes as they happen.

This takes four steps in total: we need to create an instance of JSONEncoder that will do the work of converting our data to JSON, we ask that to try encoding our items array, and then we can write that to UserDefaults using the key “Items”.
Modify the items property to this:

@Published var items = [ExpenseItem]() {
    didSet {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "Items")
        }
    }
}

Tip: Using JSONEncoder().encode() means “create an encoder and use it to encode something,” all in one step, rather than creating the encoder first then using it later.

Now, if you’re following along you’ll notice that code doesn’t actually compile. And if you’re following along closely you’ll have noticed that I said this process takes four steps while only listing three.

The problem is that the encode() method can only archive objects that conform to the Codable protocol. Remember, conforming to Codable is what asks the compiler to generate code for us able to handle archiving and unarchiving objects, and if we don’t add a conformance for that then our code won’t build.

Helpfully, we don’t need to do any work other than add Codable to ExpenseItem, like this:

struct ExpenseItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let type: String
    let amount: Int
}

Swift already includes Codable conformances for the UUID, String, and Int properties of ExpenseItem, and so it’s able to make ExpenseItem conform automatically as soon as we ask for it.

However, you will see a warning that id will not be decoded because we made it a constant and assigned a default value. This is actually the behavior we want, but Swift is trying to be helpful because it’s possible you did plan to decode this value from JSON. To make the warning go away, make the property variable like this:

var id = UUID()

With that change, we’ve written all the code needed to make sure our items are saved when the user adds them. However, it’s not effective by itself: the data might be saved, but it isn’t loaded again when the app relaunches.

To solve that – and also to make our code compile again – we need to implement a custom initializer. That will:

1. Attempt to read the “Items” key from UserDefaults.
2. Create an instance of JSONDecoder, which is the counterpart of JSONEncoder that lets us go from JSON data to Swift objects.
3. Ask the decoder to convert the data we received from UserDefaults into an array of ExpenseItem objects.
4. If that worked, assign the resulting array to items and exit.
5. Otherwise, set items to be an empty array.

Add this initializer to the Expenses class now:

init() {
    if let savedItems = UserDefaults.standard.data(forKey: "Items") {
        if let decodedItems = try? JSONDecoder().decode([ExpenseItem].self, from: savedItems) {
            items = decodedItems
            return
        }
    }

    items = []
}

The two key parts of that code are the data(forKey: "Items") line, which attempts to read whatever is in “Items” as a Data object, and try? JSONDecoder().decode([ExpenseItem].self, from: savedItems), which does the actual job of unarchiving the Data object into an array of ExpenseItem objects.

It’s common to do a bit of a double take when you first see [ExpenseItem].self – what does the .self mean? Well, if we had just used [ExpenseItem], Swift would want to know what we meant – are we trying to make a copy of the class? Were we planning to reference a static property or method? Did we perhaps mean to create an instance of the class? To avoid confusion – to say that we mean we’re referring to the type itself, known as the type object – we write .self after it.




