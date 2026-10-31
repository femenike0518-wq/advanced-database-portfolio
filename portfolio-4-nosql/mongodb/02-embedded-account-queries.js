// Run in mongosh after 01-swiftbank-documents.js.
var swiftbank = db.getSiblingDB("swiftbank_nosql");

print("Embedded account details for each SwiftBank customer:");
printjson(swiftbank.customers.find(
  {},
  { _id: 0, customer_id: 1, full_name: 1, email: 1, accounts: 1, recent_transactions: 1 }
).sort({ customer_id: 1 }).toArray());

print("Customers with a savings account:");
printjson(swiftbank.customers.find(
  { "accounts.account_type": "savings" },
  { _id: 0, customer_id: 1, full_name: 1, "accounts.account_number": 1 }
).sort({ customer_id: 1 }).toArray());
