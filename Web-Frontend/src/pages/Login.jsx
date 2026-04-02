import { useEffect, useMemo, useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext.jsx'
import { USE_MOCK } from '../config.js'

function BloodLinkLogo() {
  return (
    <div className="flex items-center justify-center gap-2">
      <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-[#C8102E] text-white">
        <span className="text-lg font-bold">🩸</span>
      </div>
      <div className="text-2xl font-extrabold tracking-tight text-[#C8102E]">Drop4Life</div>
    </div>
  )
}

function TabButton({ active, onClick, children }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={[
        'rounded-full px-4 py-2 text-sm font-semibold transition',
        active ? 'bg-white text-[#C8102E] shadow-sm' : 'text-[#6B7280] hover:text-[#111827]',
      ].join(' ')}
    >
      {children}
    </button>
  )
}

function getErrorText(error) {
  const code = error?.code || ''
  if (code === 'app/firebase-not-configured') return 'Firebase is not configured yet (frontend-only mode).'
  if (code.includes('auth/invalid-credential')) return 'Invalid email or password.'
  if (code.includes('auth/too-many-requests')) return 'Too many attempts. Please try again later.'
  return 'Login failed. Please try again.'
}

export default function Login() {
  const navigate = useNavigate()
  const { user, role, loading, login, error } = useAuth()

  const [mode, setMode] = useState('hospital')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [staySignedIn, setStaySignedIn] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [localError, setLocalError] = useState(null)

  const canSubmit = useMemo(() => email.trim() && password, [email, password])

  useEffect(() => {
    if (!user || !role) return
    if (role === 'hospital') navigate('/hospital/dashboard', { replace: true })
    if (role === 'admin') navigate('/admin/dashboard', { replace: true })
  }, [user, role, navigate])

  if (user && role) return <Navigate to="/" replace />

  async function onSubmit(e) {
    e.preventDefault()
    setLocalError(null)
    if (!canSubmit) {
      setLocalError('Please enter your email and password.')
      return
    }

    if (USE_MOCK) {
      if (mode === 'hospital') navigate('/hospital/dashboard', { replace: true })
      if (mode === 'admin') navigate('/admin/dashboard', { replace: true })
      return
    }

    setSubmitting(true)
    try {
      await login(email.trim(), password)
      if (!staySignedIn) {
        window.setTimeout(() => {
          window.dispatchEvent(
            new CustomEvent('app:toast', {
              detail: {
                type: 'info',
                message: 'Session set for 24 hours (backend enforcement recommended).',
              },
            }),
          )
        }, 200)
      }
    } catch (e2) {
      setLocalError(getErrorText(e2))
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="relative min-h-screen bg-[#F7F7F7] text-[#111827]">

      <div className="mx-auto flex min-h-screen max-w-6xl items-center justify-center px-6 py-12 md:justify-center">
        <div className="w-full max-w-md rounded-2xl border border-[#E5E7EB] bg-white p-8 shadow-sm">
          <div className="space-y-2 text-center">
            <BloodLinkLogo />
            <div className="text-xs font-semibold tracking-[0.2em] text-[#6B7280]">
              LIFE-SAVING NETWORK ACCESS
            </div>
          </div>

          <div className="mt-6 rounded-full bg-[#F7F7F7] p-1">
            <div className="flex items-center justify-center gap-2">
              <TabButton active={mode === 'hospital'} onClick={() => setMode('hospital')}>
                Hospital View
              </TabButton>
              <TabButton active={mode === 'admin'} onClick={() => setMode('admin')}>
                System Admin
              </TabButton>
            </div>
          </div>

          <form onSubmit={onSubmit} className="mt-6 space-y-4">
            <div>
              <label className="block text-xs font-semibold text-[#6B7280]">PROFESSIONAL EMAIL</label>
              <input
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="name@medical-center.org"
                type="email"
                autoComplete="email"
                className="mt-2 w-full rounded-xl border border-[#E5E7EB] bg-white px-4 py-3 text-sm outline-none focus:border-[#C8102E]"
              />
            </div>

            <div>
              <div className="flex items-center justify-between">
                <label className="block text-xs font-semibold text-[#6B7280]">SECURE PASSWORD</label>
                <button
                  type="button"
                  className="text-xs font-semibold text-[#C8102E] hover:underline"
                >
                  Forgot?
                </button>
              </div>
              <input
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••••"
                type="password"
                autoComplete="current-password"
                className="mt-2 w-full rounded-xl border border-[#E5E7EB] bg-white px-4 py-3 text-sm outline-none focus:border-[#C8102E]"
              />
            </div>

            <div className="flex items-center justify-between">
              <label className="flex cursor-pointer items-center gap-2 text-sm text-[#111827]">
                <input
                  type="checkbox"
                  checked={staySignedIn}
                  onChange={(e) => setStaySignedIn(e.target.checked)}
                  className="h-4 w-4 rounded border-[#E5E7EB] text-[#C8102E] focus:ring-[#C8102E]"
                />
                Stay signed in for 24 hours
              </label>
            </div>

            {(localError || error) && (
              <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                {localError || getErrorText(error)}
              </div>
            )}

            <button
              type="submit"
              disabled={!canSubmit || submitting || loading}
              className={[
                'w-full rounded-xl bg-[#C8102E] px-4 py-3 text-sm font-semibold text-white shadow-sm',
                'disabled:cursor-not-allowed disabled:opacity-60',
              ].join(' ')}
            >
              {submitting ? 'Signing in…' : 'Dashboard Login'}
            </button>
          </form>

          <div className="mt-6 flex items-center justify-center gap-4 text-xs text-[#6B7280]">
            <button type="button" className="hover:text-[#111827] hover:underline">
              Privacy Protocols
            </button>
            <span>•</span>
            <button type="button" className="hover:text-[#111827] hover:underline">
              System Status
            </button>
            <span>•</span>
            <button type="button" className="hover:text-[#111827] hover:underline">
              Technical Support
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

