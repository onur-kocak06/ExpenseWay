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
                // Add the transaction to the data model
                // Close the sheet
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
}

struct TransactionHistoryView: View {
    var body: some View {
        // Implement transaction history view
        Text("Transaction History")
            .navigationBarItems(leading: NavigationLink("Back", destination: DashboardView()))
    }
}
struct FriendsListView: View {
    @State private var friends: [Friend] = []

    var body: some View {
        List(friends, id: \.id) { friend in
                    Text(friend.name)
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



#Preview {
    ContentView()
}
