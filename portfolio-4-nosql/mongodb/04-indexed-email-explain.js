// Run in mongosh after 01-swiftbank-documents.js.
var swiftbank = db.getSiblingDB("swiftbank_nosql");

print("Indexes on the customers collection:");
printjson(swiftbank.customers.getIndexes());

print("Validator configured on the customers collection:");
printjson(swiftbank.getCollectionInfos({ name: "customers" }));

print("Execution statistics for the selective unique-email lookup:");
printjson(swiftbank.customers.find(
  { email: "daniel@test.com" },
  { _id: 0, customer_id: 1, full_name: 1, email: 1 }
).explain("executionStats"));
