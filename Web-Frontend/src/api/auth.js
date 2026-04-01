import { initializeApp } from 'firebase/app'
import {
  getAuth,
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged as firebaseOnAuthStateChanged,
} from 'firebase/auth'

// console.log("Firebase configured:", isFirebaseConfigured)

function getFirebaseConfig() {
  return {
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
    appId: import.meta.env.VITE_FIREBASE_APP_ID,
  }
}

export const isFirebaseConfigured = Boolean(
  import.meta.env.VITE_FIREBASE_API_KEY &&
    import.meta.env.VITE_FIREBASE_AUTH_DOMAIN &&
    import.meta.env.VITE_FIREBASE_PROJECT_ID &&
    import.meta.env.VITE_FIREBASE_APP_ID,
)

let firebaseAuth = null

function ensureFirebaseAuth() {
  if (firebaseAuth) return firebaseAuth
  if (!isFirebaseConfigured) return null

  const app = initializeApp(getFirebaseConfig())
  firebaseAuth = getAuth(app)
  return firebaseAuth
}

export { firebaseAuth }

export async function login(email, password) {
  const auth = ensureFirebaseAuth()
  if (!auth) {
    const err = new Error('Firebase is not configured. Add env vars to enable login.')
    err.code = 'app/firebase-not-configured'
    throw err
  }

  const result = await signInWithEmailAndPassword(auth, email, password)
  return result.user
}

export async function logout() {
  const auth = ensureFirebaseAuth()
  if (!auth) return
  await signOut(auth)
}

export function onAuthStateChanged(callback) {
  const auth = ensureFirebaseAuth()
  if (!auth) {
    callback(null)
    return () => {}
  }

  return firebaseOnAuthStateChanged(auth, callback)
}

