const fs = require('node:fs');
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

const projectId = 'irfandevs77-d9520';
const uid = process.argv[2];

async function main() {
  const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

  if (!uid) {
    throw new Error(
      'Usage: npm run set-admin -- <Firebase Authentication user UID>',
    );
  }

  if (!credentialsPath || !fs.existsSync(credentialsPath)) {
    throw new Error(
      'Set GOOGLE_APPLICATION_CREDENTIALS to the path of a trusted Firebase service-account JSON file stored outside this project.',
    );
  }

  initializeApp({
    credential: applicationDefault(),
    projectId,
  });

  const auth = getAuth();
  const user = await auth.getUser(uid);
  const claims = { ...user.customClaims, admin: true };

  console.log(`Project: ${projectId}`);
  console.log(`Account: ${user.email ?? '(no email)'} (${user.uid})`);

  await auth.setCustomUserClaims(uid, claims);

  console.log(
    'Admin custom claim set. Sign out and sign in again to refresh it.',
  );
}

main().catch((error) => {
  console.error(`Failed to set admin claim: ${error.message}`);
  process.exitCode = 1;
});