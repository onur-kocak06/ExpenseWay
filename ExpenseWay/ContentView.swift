import SwiftUI
import Firebase
import FirebaseFirestore
import SwiftUICharts
import CoreLocation









struct ContentView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggedIn = false
   
    var body: some View {
        
        
        
        
        
        
        
        
        NavigationView {
            if isLoggedIn {
                DashboardView()
            } else {
                //DashboardView()
                
                //Pie()
                
                 WelcomeView(email: $email, password: $password, isLoggedIn: $isLoggedIn)
                 .navigationTitle("Welcome")
                 
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
            Button(action: {
                signUpWithFirebase()
            }) {
                Text("Sign Up")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }
        .padding()

    }
    private func signUpWithFirebase() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Sign up failed: \(error.localizedDescription)")
            } else {
                isLoggedIn = true

            }
        }
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
                    .background(Color.green)
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
            NavigationLink(destination:  Pie()) {
                Text("See charts")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(8)
            }


        }
        .padding()
    }
}

struct AddTransactionView: View {
    
    
    private func getLocationInfo() {
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()

        if let location = locationManager.location {
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
                if let place = placemarks?.first {
                    if let city = place.locality {
                        self.userCity = city
                    } else {
                        self.userCity = "ERR"
                    }
                    
                    if let country = place.country {
                        self.userCountry = country
                    } else {
                        self.userCountry = "ERR"
                    }
                } else {
                    self.userCity = "ERR"
                    self.userCountry = "ERR"
                }
            }
        } else {
            self.userCity = "ERR"
            self.userCountry = "ERR"
        }
    }
    
    
    
    @State private var userCity = "NF"
    @State private var userCountry = "NF"
  
    @State private var totalAmount = ""
    @State private var selectedFriendIndex = 0
    @State private var selectedCategoryIndex = 0
    @State private var friends: [Friend] = []
    @State private var description = ""
    @Environment(\.presentationMode) var presentationMode


    let categories: [String] = ["Groceries", "Utilities", "Transport", "Gift and donations", "Restaurant", "Clothing", "Other"]

    var body: some View {
        Form {
            TextField("Total Amount", text: $totalAmount)
            Picker("Select Payer", selection: $selectedFriendIndex) {
                ForEach(0..<friends.count, id: \.self) { index in
                    Text(friends[index].name)
                }
            }
            Picker("Select Category", selection: $selectedCategoryIndex) {
                ForEach(0..<categories.count, id: \.self) { index in
                    Text(categories[index])
                }
            }
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
        .onAppear {
            fetchFriends()
            getLocationInfo()
        }
        .padding()
        .navigationTitle("Add an Expense")
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
    private func addTransaction() {
        
        guard let amount = Double(totalAmount),
              selectedFriendIndex < friends.count,
              selectedCategoryIndex < categories.count else {

            return
        }

        let selectedFriend = friends[selectedFriendIndex]
        let selectedCategory = categories[selectedCategoryIndex]

        let db = Firestore.firestore()
        let newTransactionRef = db.collection("transactions").document()
        let transactionData: [String: Any] = [
            "id": newTransactionRef.documentID,
            "totalAmount": amount,
            "payerName": selectedFriend.name,
            "category": selectedCategory,
            "description": description,
            "timestamp": FieldValue.serverTimestamp(),
            "location": userCountry+", "+userCity
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
                    Text("Location: \(transaction.location)")
                    Text("Description: \(transaction.description)")
                }
            }
        }
        .onAppear {
            fetchTransactions()
        }
        .navigationTitle("Transactions")
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
            Text("Location: \(transaction.location)")
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
        //print("Deleting transaction with ID: \(transaction.id)")
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

                VStack(alignment: .leading) {
                    Text("Amount: \(transaction.totalAmount)")
                    Text("Payer: \(transaction.payerName)")
                    Text("Description: \(transaction.description)")
                }
            }
            .onAppear {
                fetchTransactions()
            }
            .navigationTitle(selectedFriend.name)

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
    @State private var selectedCategoryIndex = 0
    @Environment(\.presentationMode) var presentationMode

    var selectedFriend: Friend

    let categories: [String] = ["Groceries", "Utilities", "Transport", "Gift and donations", "Restaurant", "Clothing", "Other"]

    var body: some View {
        Form {
            TextField("Total Amount", text: $totalAmount)

            Picker("Select Category", selection: $selectedCategoryIndex) {
                ForEach(0..<categories.count, id: \.self) { index in
                    Text(categories[index])
                }
            }

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
        guard let amount = Double(totalAmount),
              selectedCategoryIndex < categories.count else {
            return
        }

        let selectedCategory = categories[selectedCategoryIndex]

        let db = Firestore.firestore()
        let newTransactionRef = db.collection("transactions").document()
        let transactionData: [String: Any] = [
            "id": newTransactionRef.documentID,
            "totalAmount": amount,
            "payerName": selectedFriend.name,
            "category": selectedCategory,
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
        .navigationTitle("Friends")
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

struct Pie: View {
    @State private var slices: [(String, Double, Color)] = []

    var body: some View {
        VStack {
            Canvas { context, size in


                let total = slices.reduce(0) { $0 + $1.1 }
                context.translateBy(x: size.width * 0.5, y: size.height * 0.5)

                var startAngle = Angle.zero
                let gapSize = Angle(degrees: 1) // size of the gap between slices in degrees
                let radius = min(size.width, size.height) * 0.48

                for (_, value, color) in slices {
                    let angle = Angle(degrees: 360 * (value / total))
                    let endAngle = startAngle + angle

                    let path = Path { p in
                        p.move(to: .zero)
                        p.addArc(center: .zero, radius: radius, startAngle: startAngle + gapSize / 2, endAngle: endAngle, clockwise: false)
                        p.closeSubpath()
                    }

                    context.fill(path, with: .color(color))
                    startAngle = endAngle
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .onAppear {
                fetchData()
            }
            .navigationTitle("Charts")

            // Legend
            VStack(spacing: 0) {
                ForEach(slices.indices, id: \.self) { index in
                    LegendItemView(category: slices[index].0, value: slices[index].1, color: slices[index].2)
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
            }

            .padding()
        }
    }

    private func fetchData() {
        let db = Firestore.firestore()
        let categories = ["Utilities", "Groceries", "Transport", "Gift and donations", "Restaurant", "Clothing", "Other"]

        db.collection("transactions").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching transactions: \(error.localizedDescription)")
            } else {
                let transactions = snapshot?.documents.compactMap { document in
                    return try? document.data(as: Transaction.self)
                } ?? []

                var categoryExpenses: [String: Double] = Dictionary(uniqueKeysWithValues: categories.map { ($0, 0) })
                var total: Double = 0

                for transaction in transactions {
                    if let category = transaction.category {
                        categoryExpenses[category, default: 0] += transaction.totalAmount
                        total += transaction.totalAmount
                    }
                }

                // Sort categories for consistent order in the chart
                let sortedCategories = categories.sorted()

                // Assign colors based on the specified order
                slices = sortedCategories.compactMap { category in
                    guard let value = categoryExpenses[category] else {
                        print("Category '\(category)' not found in expenses. Defaulting to gray.")
                        return nil
                    }

                    let minimumAngle: Double = 5
                    //i dont know why but any smaller and charts break completely
                    let angle = max((360 * (value / total)), minimumAngle)

                    let color: Color
                    switch category.lowercased() {
                    case "utilities":
                        color = .red
                    case "groceries":
                        color = .yellow
                    case "transport":
                        color = .blue
                    case "gift and donations":
                        color = .purple
                    case "restaurant":
                        color = .green
                    case "clothing":
                        color = .black
                    case "other":
                        color = .gray
                    default:
                        color = .gray
                    }

                    return (category, angle, color)
                }
            }
        }
    }
}


struct LegendItemView: View {
    var category: String
    var value: Double
    var color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)

            Spacer()

            VStack(alignment: .leading) {
                Text(category)
                    .foregroundColor(.primary)
                    .font(.caption)
                    .lineLimit(1)

            }

            Spacer()
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
    var category: String?
    var description: String
    var location: String
    var timestamp: Timestamp

    enum CodingKeys: String, CodingKey {
        case id
        case totalAmount
        case payerName
        case category
        case description
        case location
        case timestamp

    }
    
}


#Preview {
    ContentView()
}



