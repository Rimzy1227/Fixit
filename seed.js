/**
 * FIREBASE EMULATOR SEED SCRIPT
 * --------------------------------------------
 * Creates:
 *  - 2 Admins
 *  - 2 Clients
 *  - 1 Contractor (verified)
 *  - 3 Providers under contractor
 *  - Service categories (Electrical, Plumbing, Cleaning)
 *  - Services inside categories
 *  - 3 Job Requests (client → provider)
 */

const admin = require("firebase-admin");

// Connect to emulator
process.env.FIREBASE_AUTH_EMULATOR_HOST = "localhost:9099";
process.env.FIRESTORE_EMULATOR_HOST = "localhost:8080";

admin.initializeApp({
  projectId: "fixit-app-17f73",
});

const auth = admin.auth();
const db = admin.firestore();

// Utility: create user
async function createUser(email, password, role) {
  const user = await auth.createUser({
    email,
    password,
  });

  await db.collection("users").doc(user.uid).set({
    email,
    role,
    createdAt: new Date(),
  });

  return user.uid;
}

async function seed() {
  console.log("🌱 Starting Firestore + Auth seed...");

  // 1️⃣ Create Admins
  const admin1 = await createUser("admin1@test.com", "admin123", "admin");
  const admin2 = await createUser("admin2@test.com", "admin123", "admin");

  console.log("✓ Admins created");

  // 2️⃣ Create Clients
  const client1 = await createUser("client1@test.com", "client123", "client");
  const client2 = await createUser("client2@test.com", "client123", "client");

  await db.collection("clients").doc(client1).set({
    firstName: "John",
    lastName: "Doe",
    phone: "0771234567",
    city: "Colombo",
  });

  await db.collection("clients").doc(client2).set({
    firstName: "Sarah",
    lastName: "Fernando",
    phone: "0719876543",
    city: "Kandy",
  });

  console.log("✓ Clients created");

  // 3️⃣ Create Contractor (verified)
  const contractor = await createUser("contractor@test.com", "contractor123", "contractor");

  await db.collection("contractors").doc(contractor).set({
    company_name: "FixPro Services",
    company_contact: "0112345678",
    verified: true,
  });

  console.log("✓ Contractor created");

  // 4️⃣ Service Providers under Contractor
  const provider1 = await createUser("provider1@test.com", "provider123", "provider");
  const provider2 = await createUser("provider2@test.com", "provider123", "provider");
  const provider3 = await createUser("provider3@test.com", "provider123", "provider");

  const providers = [provider1, provider2, provider3];

  for (const p of providers) {
    await db
      .collection("contractors")
      .doc(contractor)
      .collection("providers")
      .doc(p)
      .set({
        name: "Provider User " + p.slice(0, 6),
        email: p + "@test.com",
        phone: "0701112222",
        approved: true,
        createdBy: contractor,
      });
  }

  console.log("✓ Providers created");

  // 5️⃣ Service Categories
  const categories = ["Electrical", "Plumbing", "Cleaning"];
  for (const cat of categories) {
    await db.collection("serviceCategories").add({ name: cat });
  }

  console.log("✓ Service categories added");

  // 6️⃣ Services
  await db.collection("services").add({
    name: "AC Repair",
    category: "Electrical",
  });

  await db.collection("services").add({
    name: "Fix Pipe Leak",
    category: "Plumbing",
  });

  await db.collection("services").add({
    name: "Full House Cleaning",
    category: "Cleaning",
  });

  console.log("✓ Services created");

  // 7️⃣ Jobs (Client → Provider)
  await db.collection("jobs").add({
    clientId: client1,
    providerId: provider1,
    service: "AC Repair",
    status: "pending",
    createdAt: new Date(),
  });

  await db.collection("jobs").add({
    clientId: client1,
    providerId: provider2,
    service: "Fix Pipe Leak",
    status: "accepted",
    createdAt: new Date(),
  });

  await db.collection("jobs").add({
    clientId: client2,
    providerId: provider3,
    service: "House Cleaning",
    status: "completed",
    createdAt: new Date(),
  });

  console.log("✓ Jobs created");

  console.log("\n🎉 SEED COMPLETE! You can now use the test accounts.");
  console.log("-----------------------------------------------------");
  console.log("ADMIN LOGIN:");
  console.log("  admin1@test.com — admin123");
  console.log("  admin2@test.com — admin123");
  console.log("CLIENT LOGIN:");
  console.log("  client1@test.com — client123");
  console.log("  client2@test.com — client123");
  console.log("CONTRACTOR LOGIN:");
  console.log("  contractor@test.com — contractor123");
  console.log("PROVIDERS LOGIN:");
  console.log("  provider1@test.com — provider123");
  console.log("  provider2@test.com — provider123");
  console.log("  provider3@test.com — provider123");
  console.log("-----------------------------------------------------");
}

seed().catch((err) => {
  console.error("❌ Seed failed:", err);
});
