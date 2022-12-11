import { initializeApp } from "firebase/app";
import { getFunctions } from 'firebase/functions';
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";


const firebaseConfig = {
    apiKey: "AIzaSyBZQDJwftOWHbuIHaNYkGvxOt1BTbBbZsQ",
    authDomain: "nfrislands.firebaseapp.com",
    projectId: "nfrislands",
    storageBucket: "nfrislands.appspot.com",
    messagingSenderId: "9159950597",
    appId: "1:9159950597:web:1fa199f9c7e9e13430f76c"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const functions = getFunctions(app);
const db = getFirestore(app);


// export default app;
export { app, db, auth, functions };
