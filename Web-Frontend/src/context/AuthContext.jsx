import { createContext, useContext, useEffect, useMemo, useState } from 'react'
import { api } from '../api/axios'
import { login as firebaseLogin, logout as firebaseLogout, onAuthStateChanged } from '../api/auth'

const AuthContext = createContext(null)

async function fetchMe() {
  const res = await api.get('/users/me')
  return res.data
}

async function fetchHospitalProfile() {
  const res = await api.get('/hospitals/me')
  return res.data
}

export function AuthProvider({ children }) {
  const [user, setUser]           = useState(null)
  const [role, setRole]           = useState(null)
  const [profile, setProfile]     = useState(null)
  const [hospital, setHospital]   = useState(null)   // ← hospital profile with lat/lng
  const [loading, setLoading]     = useState(true)
  const [error, setError]         = useState(null)

  useEffect(() => {
    const unsub = onAuthStateChanged(async (firebaseUser) => {
      setError(null)
      setUser(firebaseUser || null)
      setRole(null)
      setProfile(null)
      setHospital(null)

      if (!firebaseUser) {
        setLoading(false)
        return
      }

      setLoading(true)
      try {
        const me = await fetchMe()
        setRole(me?.role || null)
        setProfile(me || null)

        // If hospital user — fetch hospital profile to get lat/lng
        if (me?.role === 'hospital') {
          try {
            const hospitalData = await fetchHospitalProfile()
            setHospital(hospitalData)
          } catch (e) {
            console.warn('Could not fetch hospital profile:', e)
          }
        }
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
      hospital,     // ← expose hospital profile
      loading,
      error,
      login,
      logout,
    }),
    [user, role, profile, hospital, loading, error],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}