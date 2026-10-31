// Run this single insert in mongosh after the P4 setup.
// It should be rejected because "business" is not an allowed account_type.
var swiftbank = db.getSiblingDB("swiftbank_nosql");
swiftbank.customers.insertOne({
  customer_id: NumberInt(4),
  full_name: "Invalid Demo Record",
  email: "invalid.demo@example.test",
  accounts: [
    {
      account_number: "SWB-INVALID-0004",
      account_type: "business",
      balance: Decimal128("1000.00")
    }
  ],
  recent_transactions: []
});
