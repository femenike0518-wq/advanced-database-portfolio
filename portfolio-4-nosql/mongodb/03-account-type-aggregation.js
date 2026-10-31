// Run in mongosh after 01-swiftbank-documents.js.
var swiftbank = db.getSiblingDB("swiftbank_nosql");

print("Account count and Decimal128 balance total by account type:");
printjson(swiftbank.customers.aggregate([
  { $unwind: "$accounts" },
  {
    $group: {
      _id: "$accounts.account_type",
      account_count: { $sum: 1 },
      total_balance: { $sum: "$accounts.balance" }
    }
  },
  { $sort: { _id: 1 } }
]).toArray());
