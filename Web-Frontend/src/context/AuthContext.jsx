import { createContext, useContext, useEffect, useMemo, useState } from 'react'
import { api } from '../api/axios'
import { login as firebaseLogin, logout as firebaseLogout, onAuthStateChanged } from '../api/auth'

const AuthContext = createContext(null)

async function fetchMe() {
  const res = await api.get('/users/me')
  return res.data
}

async function fetchHospital() {
  const res = await api.get('/hospitalme')
  return res.data
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [role, setRole] = useState(null)
  const [profile, setProfile] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    const unsub = onAuthStateChanged(async (firebaseUser) => {
      setError(null)
      setUser(firebaseUser || null)
      setRole(null)
      setProfile(null)

      if (!firebaseUser) {
        setLoading(false)
        return
      }

      setLoading(true)
      try {
        try {
          const hospital = await fetchHospital()
          setRole('hospital')        // HospitalResponse has no role field, we set it manually
          setProfile(hospital)
          return                     // ✅ found — stop here
        } catch (e) {
          // Not a hospital, try user endpoint
        }

        const userData = await fetchMe()
        setRole(userData.role)      // UserResponse has role field
        setProfile(userData)
      } catch (e) {
        setError(e)
      } finally {
        setLoading(false)
      }
    })

    return () => unsub()
  }, [])

  async function login(email, password) {
    setError(null)
    setLoading(true)
    try {
      await firebaseLogin(email, password)
    } catch (e) {
      setError(e)
      setLoading(false)
      throw e
    }
  }

  async function logout() {
    await firebaseLogout()
  }

  const value = useMemo(
    () => ({
      user,
      role,
      profile,
      loading,
      error,
      login,
      logout,
    }),
    [user, role, profile, loading, error],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}

