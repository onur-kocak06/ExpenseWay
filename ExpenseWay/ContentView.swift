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
            NavigationLink(destination: AddTransactionView()) {
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

struct AddTransactionView: View {
    @State private var totalAmount = ""
    @State private var payerName = ""
    @State private var description = ""
    @Environment(\.presentationMode) var presentationMode
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
        let newTransactionRef = db.collection("transactions").document()
        let transactionData: [String: Any] = [
            "id": newTransactionRef.documentID,
            "totalAmount": amount,
            "payerName": payerName,
            "description": description,
            "timestamp": FieldValue.serverTimestamp()
        ]

        newTransactionRef.setData(transactionData) { error in
            if let error = error {
                print("Error adding transaction: \(error.localizedDescription)")
            } else {
                self.presentationMode.wrappedValue.dismiss()
            }
        }

    }
}
struct TransactionHistoryView: View {
    @State private var transactions: [Transaction] = []
    @State private var selectedTransaction: Transaction?

    var body: some View {
        List(transactions) { transaction in
            NavigationLink(destination: TransactionDetailsView(transaction: transaction)) {
                VStack(alignment: .leading) {
                    Text("Amount: \(transaction.totalAmount)")
                    Text("Payer: \(transaction.payerName)")
                    Text("Description: \(transaction.description)")
                }
            }
        }
        .onAppear {
            fetchTransactions()
        }
    }

    private func fetchTransactions() {
        let db = Firestore.firestore()
        db.collection("transactions").order(by: "timestamp", descending: true).getDocuments { snapshot, error in
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
struct TransactionDetailsView: View {
    var transaction: Transaction
    @Environment(\.presentationMode) var presentationMode


    var body: some View {
        VStack(alignment: .leading) {
            Text("Amount: \(transaction.totalAmount)")
            Text("Payer: \(transaction.payerName)")
            Text("Description: \(transaction.description)")

            Button(action: {
                deleteTransaction()
            }) {
                Text("Delete Transaction")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
            }
        }
        .padding()
        .navigationTitle("Transaction Details")
    }

    private func deleteTransaction() {
        print("Deleting transaction with ID: \(transaction.id)")
        let db = Firestore.firestore()
        db.collection("transactions").document(transaction.id).delete { error in
            if let error = error {
                print("Error deleting transaction: \(error.localizedDescription)")
            } else {
                //print("Transaction deleted successfully")
                self.presentationMode.wrappedValue.dismiss()
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

            NavigationLink(destination: AddTransactionWithFriendView(selectedFriend: selectedFriend)) {
                Text("Add Transaction with \(selectedFriend.name)")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }

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
struct AddTransactionWithFriendView: View {
    @State private var totalAmount = ""
    @State private var description = ""
    @Environment(\.presentationMode) var presentationMode

    var selectedFriend: Friend

    var body: some View {
        Form {
            TextField("Total Amount", text: $totalAmount)
            TextField("Description", text: $description)

            Button(action: {
                addTransactionSpecific()
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

    private func addTransactionSpecific() {
        guard let amount = Double(totalAmount) else {
            // Handle invalid amount
            return
        }

        let db = Firestore.firestore()
        let newTransactionRef = db.collection("transactions").document()
        let transactionData: [String: Any] = [
            "id": newTransactionRef.documentID,
            "totalAmount": amount,
            "payerName": selectedFriend.name,
            "description": description,
            "timestamp": FieldValue.serverTimestamp()
        ]

        newTransactionRef.setData(transactionData) { error in
            if let error = error {
                print("Error adding transaction: \(error.localizedDescription)")
            } else {
                self.presentationMode.wrappedValue.dismiss()
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
        .navigationBarItems(
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
    @Environment(\.presentationMode) var presentationMode

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
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}




struct Friend: Identifiable, Codable {
    var id: String
    var name: String
    
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
