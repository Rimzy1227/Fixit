// test/firestore_test.js
import { initializeTestEnvironment, assertFails, assertSucceeds } from "@firebase/rules-unit-testing";
import { readFileSync } from "fs";
import { doc, setDoc } from "firebase/firestore";

const PROJECT_ID = "fixit-app";
const rules = readFileSync("firestore.rules", "utf8");

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

describe("FixIt Firestore Security Rules", () => {
  test("Unauthenticated user cannot write to clients collection", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    const ref = doc(db, "clients/testUser");
    await assertFails(setDoc(ref, { name: "Hacker" }));
  });

  test("Authenticated client can write to their own profile", async () => {
    const client = testEnv.authenticatedContext("client123", { role: "client" });
    const db = client.firestore();
    const ref = doc(db, "clients/client123");
    await assertSucceeds(setDoc(ref, { name: "Valid Client" }));
  });

  test("Authenticated client cannot write to another client’s profile", async () => {
    const client = testEnv.authenticatedContext("client123", { role: "client" });
    const db = client.firestore();
    const ref = doc(db, "clients/otherClient");
    await assertFails(setDoc(ref, { name: "Hacker" }));
  });
});
