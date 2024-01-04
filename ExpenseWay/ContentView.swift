import SwiftUI
import Firebase
import FirebaseFirestore

struct ContentView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggedIn = false

    var body: some View {
        NavigationView {
            if isLoggedIn {
                DashboardView()
            } else {
                DashboardView()
                /*
                WelcomeView(email: $email, password: $password, isLoggedIn: $isLoggedIn)
                    .navigationTitle("Welcome")
                */
            }
        }
    }
}

struct WelcomeView: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var isLoggedIn: Bool

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .padding()
            SecureField("Password", text: $password)
                .padding()

            Button(action: {
                loginWithFirebase()
            }) {
                Text("Login")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
    }

    private func loginWithFirebase() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Login failed: \(error.localizedDescription)")
            } else {
                isLoggedIn = true
            }
        }
    }
}

struct DashboardView: View {
    var body: some View {
        VStack {
            Text("Welcome to ExpenseWay")
                .font(.title)
                .padding()
            NavigationLink(destination: FriendsListView()) {
                            Text("Manage Friends")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green) // Use a different color for the friends button
                                .cornerRadius(8)
                        }
            NavigationLink(destination: AddExpenseView()) {
                Text("Add an Expense")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
            }

            NavigationLink(destination: TransactionHistoryView()) {
                Text("Transaction History")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }

        }
        .padding()
    }
}

struct AddExpenseView: View {
    @State private var totalAmount = ""
    @State private var payerName = ""
    @State private var description = ""

    var body: some View {
        Form {
            TextField("Total Amount", text: $totalAmount)
            TextField("Payer Name", text: $payerName)
            TextField("Description", text: $description)

            Button(action: {
                addTransaction()
            }) {
                Text("Add Transaction")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
            }
        }
        .padding()
        .navigationTitle("Add an Expense")
    }

    private func addTransaction() {
        guard let amount = Double(totalAmount) else {
            // Handle invalid amount
            return
        }

        let db = Firestore.firestore()
        let transactionData: [String: Any] = [
            "id": UUID().uuidString, // Generate a unique ID
            "totalAmount": amount,
            "payerName": payerName,
            "description": description,
            "timestamp": FieldValue.serverTimestamp() // Add timestamp for sorting
        ]

        db.collection("transactions").addDocument(data: transactionData) { error in
            if let error = error {
                print("Error adding transaction: \(error.localizedDescription)")
            } else {
                //print("Transaction added successfully")
                // Close the sheet or navigate to another view if needed
            }
        }
    }
}
struct TransactionHistoryView: View {
    @State private var transactions: [Transaction] = []

    var body: some View {
        List(transactions) { transaction in
            VStack(alignment: .leading) {
                Text("Amount: \(transaction.totalAmount)")
                Text("Payer: \(transaction.payerName)")
                Text("Description: \(transaction.description)")
            }
        }
        .onAppear {
            fetchTransactions()
        }
        .navigationBarItems(leading: NavigationLink("Back", destination: DashboardView()))
    }

    private func fetchTransactions() {
        let db = Firestore.firestore()
        db.collection("transactions").order(by: "timestamp", descending: true).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching transactions: \(error.localizedDescription)")
            } else {
                transactions = snapshot?.documents.compactMap { document in
                    //print(document.data())
                    return try? document.data(as: Transaction.self)
                } ?? []
            }
        }
    }
}

struct TransactionWithFriend: View {
    @State private var transactions: [Transaction] = []
    var selectedFriend: Friend

    var body: some View {
        VStack {
            List(transactions) { transaction in
                // Display transactions for the selected friend
                VStack(alignment: .leading) {
                    Text("Amount: \(transaction.totalAmount)")
                    Text("Payer: \(transaction.payerName)")
                    Text("Description: \(transaction.description)")
                }
            }
            .onAppear {
                fetchTransactions()
            }

            NavigationLink(destination: AddTransactionView(selectedFriend: selectedFriend)) {
                Text("Add Transaction with \(selectedFriend.name)")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }
        .navigationBarItems(leading: NavigationLink("Back", destination: DashboardView()))
    }

    private func fetchTransactions() {
        let db = Firestore.firestore()
        db.collection("transactions")
            .whereField("payerName", isEqualTo: selectedFriend.name)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching transactions: \(error.localizedDescription)")
                } else {
                    transactions = snapshot?.documents.compactMap { document in
                        return try? document.data(as: Transaction.self)
                    } ?? []
                }
            }
    }
}
struct AddTransactionView: View {
    @State private var totalAmount = ""
    @State private var description = ""
    var selectedFriend: Friend

    var body: some View {
        Form {
            TextField("Total Amount", text: $totalAmount)
            TextField("Description", text: $description)

            Button(action: {
                addTransaction()
            }) {
                Text("Add Transaction")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
            }
        }
        .padding()
        .navigationTitle("Add Transaction with \(selectedFriend.name)")
    }

    private func addTransaction() {
        guard let amount = Double(totalAmount) else {
            // Handle invalid amount
            return
        }

        let db = Firestore.firestore()
        let transactionData: [String: Any] = [
            "id": UUID().uuidString,
            "totalAmount": amount,
            "payerName": selectedFriend.name,
            "description": description,
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("transactions").addDocument(data: transactionData) { error in
            if let error = error {
                print("Error adding transaction: \(error.localizedDescription)")
            } else {
                // Transaction added successfully, you may navigate back or perform other actions
            }
        }
    }
}




struct FriendsListView: View {
    @State private var friends: [Friend] = []
        @State private var selectedFriend: Friend?

        var body: some View {
            List(friends, id: \.id) { friend in
                NavigationLink(destination: TransactionWithFriend(selectedFriend: friend)) {
                    Text(friend.name)
                }
            }
            .onAppear {
                fetchFriends()
            }
            .navigationBarItems(leading: NavigationLink("Back", destination: DashboardView()),
                                trailing: NavigationLink(destination: AddFriendView()) {
                                    Text("Add Friend")
                                })
        }
    private func fetchFriends() {
        let db = Firestore.firestore()
        db.collection("friends").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching friends: \(error.localizedDescription)")
            } else {
                friends = snapshot?.documents.compactMap { document in
                    //print("Friend document data: \(document.data())")

                    return try? document.data(as: Friend.self)
                } ?? []

                //print("Fetched friends: \(friends)")
            }
        }
    }
}
struct AddFriendView: View {
    @State private var newFriendName = ""

    var body: some View {
        VStack {
            TextField("Friend's Name", text: $newFriendName)
                .padding()

            Button(action: {
                addFriend()
            }) {
                Text("Add Friend")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }
        .padding()
        .navigationTitle("Add Friend")
    }

    private func addFriend() {
        let db = Firestore.firestore()
        let friendData: [String: Any] = [
            "id": UUID().uuidString, // Generate a unique ID
            "name": newFriendName
        ]

        db.collection("friends").addDocument(data: friendData) { error in
            if let error = error {
                print("Error adding friend: \(error.localizedDescription)")
            } else {
                //print("Friend added successfully")
            }
        }
    }
}


struct FriendsSelectionView: View {
    @Binding var selectedFriends: [String]

    var body: some View {
        // Implement UI to select friends from the list
        // Update the selectedFriends array accordingly
        Text("Select Friends")
    }
}

struct Friend: Identifiable, Codable {
    var id: String
    var name: String
    // Add any other properties you need for a friend
}
struct Transaction: Identifiable, Codable {
    var id: String
    var totalAmount: Double
    var payerName: String
    var description: String
    var timestamp: Timestamp

    enum CodingKeys: String, CodingKey {
        case id
        case totalAmount
        case payerName
        case description
        case timestamp
    }
}


#Preview {
    ContentView()
}
