const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
require('dotenv').config();

admin.initializeApp();
const db = admin.firestore();

// Setup nodemailer transporter using SMTP or use SendGrid/Mailgun API
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: Number(process.env.SMTP_PORT || 587),
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

async function sendEmail(to, subject, text, html) {
  const mailOptions = {
    from: process.env.FROM_EMAIL,
    to,
    subject,
    text,
    html,
  };
  return transporter.sendMail(mailOptions);
}

// 1) When contractor status updated to 'approved', flag user and send email
exports.onContractorStatusChange = functions.firestore
  .document('contractors/{contractorId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status !== 'approved' && after.status === 'approved') {
      const createdBy = after.createdBy;
      // update users collection approved flag
      await db.collection('users').doc(createdBy).update({ approved: true });
      // try to get user's email
      const userDoc = await db.collection('users').doc(createdBy).get();
      const email = userDoc.exists ? userDoc.data().email : null;
      if (email) {
        await sendEmail(email, 'Contractor Approved', `Your contractor account has been approved.`, `<p>Your contractor account has been approved. You can now add providers and accept jobs.</p>`);
      }
      // Optionally send FCM message if token present
      try {
        const token = userDoc.data().fcmToken;
        if (token) {
          await admin.messaging().sendToDevice(token, {
            notification: { title: 'Account Approved', body: 'Your contractor account is approved.' },
            data: { type: 'contractor_approved' }
          });
        }
      } catch (e) {
        console.log('FCM error (maybe no token):', e.message);
      }
    }
  });

// 2) When a contractor adds provider (doc created), auto-create Firebase Auth user and send email with temporary password
exports.onProviderCreated = functions.firestore
  .document('contractors/{contractorId}/providers/{providerId}')
  .onCreate(async (snap, ctx) => {
    const data = snap.data();
    const email = data.email;
    const displayName = data.name || 'Provider';
    if (!email) {
      console.log('Provider created without email; skipping auth creation.');
      return null;
    }

    // generate a random temp password (8 chars)
    const tempPassword = Math.random().toString(36).slice(-8);
    try {
      const userRecord = await admin.auth().createUser({
        email,
        password: tempPassword,
        displayName,
      });
      // link provider doc to auth userId
      await snap.ref.update({ userId: userRecord.uid, tempPasswordGeneratedAt: admin.firestore.FieldValue.serverTimestamp() });

      // send email with instructions (force reset recommended)
      await sendEmail(email, 'Your Provider Account', `An account for ${displayName} was created. Temporary password: ${tempPassword}\nPlease log in and change your password.`, `<p>An account for <b>${displayName}</b> was created. Temporary password: <b>${tempPassword}</b></p><p>Please log in and change your password immediately.</p>`);
      return null;
    } catch (err) {
      console.error('Error creating provider auth user:', err);
      // mark provider doc with error
      await snap.ref.update({ authCreationError: err.message });
      return null;
    }
  });
