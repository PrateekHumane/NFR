// import {recoverPersonalSignature} from "@metamask/eth-sig-util";
const ethSigUtil = require("@metamask/eth-sig-util");

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");


admin.initializeApp();

// import * as corsLib from 'cors';
// const cors = corsLib({
//   origin: true,
// });

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.getNonceToSign = functions.https.onCall(async (data, context) => {
  if (!data.address) {
    throw new functions.https.HttpsError("invalid-argument",
        "pass wallet address");
  }

  let walletAddress = data.address.toLowerCase();
  if (walletAddress.length === 42 && walletAddress.slice(0, 2)==="0x") {
    walletAddress = walletAddress.slice(2);
  }
  if (walletAddress.length !== 40) {
    throw new functions.https.HttpsError("invalid-argument",
        "pass wallet address (as hex string length 40)");
  }

  // Get the user document for that address
  const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(walletAddress)
      .get();

  // The user document exists already, so just return the nonce
  if (userDoc.exists) {
    const existingNonce = userDoc.data()?.nonce;

    return {nonce: existingNonce};
    // The user document does not exist, create it first
  } else {
    const generatedNonce = crypto.randomBytes(8).toString("hex");

    // Create an Auth user with wallet address
    const createdUser = await admin.auth().createUser({
      uid: walletAddress,
    });

    // Associate the nonce with that user
    await admin.firestore().collection("users").doc(createdUser.uid).set({
      nonce: generatedNonce,
    });

    return {nonce: generatedNonce};
  }
});

exports.verifySignedMessage = functions.https.onCall(async (data, context) => {
  if (!data.address) {
    throw new functions.https.HttpsError("invalid-argument",
        "pass wallet address");
  }

  let walletAddress = data.address.toLowerCase();
  if (walletAddress.length === 42 && walletAddress.slice(0, 2)==="0x") {
    walletAddress = walletAddress.slice(2);
  }
  if (walletAddress.length !== 40) {
    throw new functions.https.HttpsError("invalid-argument",
        "pass wallet address (as hex string length 40)");
  }

  if (!data.signature) {
    throw new functions.https.HttpsError("invalid-argument",
        "pass signed message");
  }

  const sig = data.signature;

  // Get the nonce for this address
  const userDocRef = admin.firestore().collection("users").doc(walletAddress);
  const userDoc = await userDocRef.get();

  if (!userDoc.exists) {
    throw new functions.https.HttpsError("invalid-argument",
        "address doesn't have an associated nonce (get nonce first)");
  }

  const existingNonce = userDoc.data()?.nonce;

  // Recover the address of the account used to create the signature.
  const recoveredAddress = ethSigUtil.recoverPersonalSignature({
    data: `0x${existingNonce}`,
    signature: sig,
  });

  console.log(recoveredAddress);
  console.log(walletAddress);
  // See if that matches the address the user is claiming the signature is from
  if (recoveredAddress !== "0x"+walletAddress) {
    throw new functions.https.HttpsError("invalid-argument",
        "signature is incorrect for associated nonce");
  }

  // The signature was verified - update the nonce to prevent replay attacks
  // update nonce
  const generatedNonce = crypto.randomBytes(8).toString("hex");
  await userDocRef.update({
    nonce: generatedNonce,
  });

  // Create a custom token for the specified address
  const firebaseToken = await admin.auth().createCustomToken(walletAddress);

  // Return the token
  return {token: firebaseToken};
});
