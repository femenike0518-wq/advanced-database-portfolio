// MIT 8103 Portfolio 4: repeatable SwiftBank MongoDB demonstration.
// This script drops and recreates only the swiftbank_nosql database.
// Do not change the database name to one containing personal or unrelated data.

var swiftbank = db.getSiblingDB("swiftbank_nosql");
swiftbank.dropDatabase();

swiftbank.createCollection("customers", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["customer_id", "full_name", "email", "accounts", "recent_transactions"],
      properties: {
        customer_id: { bsonType: "int", minimum: 1 },
        full_name: { bsonType: "string", minLength: 1 },
        email: { bsonType: "string", minLength: 3 },
        accounts: {
          bsonType: "array",
          minItems: 1,
          items: {
            bsonType: "object",
            required: ["account_number", "account_type", "balance"],
            properties: {
              account_number: { bsonType: "string", minLength: 1 },
              account_type: { bsonType: "string", enum: ["savings", "current"] },
              balance: { bsonType: "decimal", minimum: Decimal128("0.00") }
            }
          }
        },
        recent_transactions: {
          bsonType: "array",
          maxItems: 5,
          items: {
            bsonType: "object",
            required: ["transaction_type", "amount", "occurred_at"],
            properties: {
              transaction_type: { bsonType: "string", enum: ["deposit", "withdrawal", "transfer"] },
              amount: { bsonType: "decimal", minimum: Decimal128("0.01") },
              occurred_at: { bsonType: "date" }
            }
          }
        }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});

swiftbank.customers.createIndex(
  { customer_id: 1 },
  { unique: true, name: "uq_customers_customer_id" }
);
swiftbank.customers.createIndex(
  { email: 1 },
  { unique: true, name: "uq_customers_email" }
);

// These three fictional records match Portfolio 1's repeatable seed data.
// Decimal128 represents money without binary floating-point rounding.
// No transaction rows were seeded in Portfolio 1, so the bounded arrays start empty.
swiftbank.customers.insertMany([
  {
    customer_id: NumberInt(1),
    full_name: "Tosin Amir",
    email: "tosin@test.com",
    accounts: [
      {
        account_number: "SWB100001",
        account_type: "savings",
        balance: Decimal128("50000.00")
      }
    ],
    recent_transactions: []
  },
  {
    customer_id: NumberInt(2),
    full_name: "Daniel Musa",
    email: "daniel@test.com",
    accounts: [
      {
        account_number: "SWB100002",
        account_type: "current",
        balance: Decimal128("80000.00")
      }
    ],
    recent_transactions: []
  },
  {
    customer_id: NumberInt(3),
    full_name: "Grace Bello",
    email: "grace@test.com",
    accounts: [
      {
        account_number: "SWB100003",
        account_type: "savings",
        balance: Decimal128("30000.00")
      }
    ],
    recent_transactions: []
  }
]);

print("Created swiftbank_nosql with three validated customer documents.");
printjson(swiftbank.customers.find({}, { _id: 0 }).sort({ customer_id: 1 }).toArray());
