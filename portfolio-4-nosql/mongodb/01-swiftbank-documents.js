
use swiftbank_nosql

db.customers.insertOne({
  customer_id: 1,
  full_name: "Tosin Amir",
  email: "tosin@test.com",
  accounts: [
    {
      account_number: "SWB100001",
      account_type: "savings",
      balance: 50000.00
    }
  ]
})

db.customers.find()


db.customers.insertMany([
  {
    customer_id: 2,
    full_name: "Daniel Musa",
    email: "daniel@example.com",
    accounts: [
      {
        account_number: "SWB100002",
        account_type: "current",
        balance: 80000.00
      }
    ]
  },
  {
    customer_id: 3,
    full_name: "Grace Bello",
    email: "grace@example.com",
    accounts: [
      {
        account_number: "SWB100003",
        account_type: "savings",
        balance: 30000.00
      }
    ]
  }
])

db.customers.find()

db.customers.updateOne(
  { customer_id: 2 },
  { $set: { email: "daniel@test.com" } }
)

db.customers.updateOne(
  { customer_id: 3 },
  { $set: { email: "grace@test.com" } }
)

db.customers.find(
  {},
  { _id: 0, customer_id: 1, full_name: 1, email: 1 }
)


db.customers.find(
  {},
  {
    _id: 0,
    customer_id: 1,
    full_name: 1,
    email: 1,
    accounts: 1
  }
)


// Find customers with savings accounts
db.customers.find({
  "accounts.account_type": "savings"
})