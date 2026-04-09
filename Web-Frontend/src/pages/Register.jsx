import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { api } from '../api/axios'

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

function Field({ label, children }) {
  return (
    <div>
      <label className="block text-xs font-semibold text-[#6B7280]">{label}</label>
      {children}
    </div>
  )
}

function Input({ value, onChange, placeholder, type = 'text', autoComplete }) {
  return (
    <input
      value={value}
      onChange={onChange}
      placeholder={placeholder}
      type={type}
      autoComplete={autoComplete}
      className="mt-2 w-full rounded-xl border border-[#E5E7EB] bg-white px-4 py-3 text-sm outline-none focus:border-[#C8102E]"
    />
  )
}

export default function Register() {
  const navigate = useNavigate()

  // Firebase account fields
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')

  // Hospital profile fields
  const [name, setName] = useState('')
  const [phone, setPhone] = useState('')
  const [address, setAddress] = useState('')
  const [city, setCity] = useState('')
  const [registrationNo, setRegistrationNo] = useState('')

  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState(null)
  const [success, setSuccess] = useState(false)

  const canSubmit = useMemo(() => (
    email.trim() && password && confirmPassword &&
    name.trim() && phone.trim() && address.trim() && city.trim()
  ), [email, password, confirmPassword, name, phone, address, city])

  async function onSubmit(e) {
    e.preventDefault()
    setError(null)

    if (password !== confirmPassword) {
      setError('Passwords do not match.')
      return
    }
    if (password.length < 6) {
      setError('Password must be at least 6 characters.')
      return
    }

    setSubmitting(true)
    try {
      // Step 1 — create Firebase account
      const { createUserWithEmailAndPassword } = await import('firebase/auth')
      const { firebaseAuth } = await import('../api/auth')
      const auth = firebaseAuth || (() => { throw new Error('Firebase not configured') })()

      const credential = await createUserWithEmailAndPassword(
        auth,
        email.trim(),
        password,
      )

      // Step 2 — get Firebase token
      const token = await credential.user.getIdToken()

      // Step 3 — register hospital on backend
      await api.post(
        '/hospitals/register',
        {
          name: name.trim(),
          phone: phone.trim(),
          address: address.trim(),
          city: city.trim(),
          registration_no: registrationNo.trim() || undefined,
        },
        { headers: { Authorization: `Bearer ${token}` } },
      )

      setSuccess(true)

      // Redirect to login after 2 seconds
      setTimeout(() => navigate('/hospital/dashboard', { replace: true }), 2000)

    } catch (err) {
      // If backend fails after Firebase account created — surface the error
      const code = err?.code || ''
      if (code.includes('auth/email-already-in-use')) {
        setError('An account already exists with this email.')
      } else if (code.includes('auth/weak-password')) {
        setError('Password must be at least 6 characters.')
      } else if (code.includes('auth/invalid-email')) {
        setError('Please enter a valid email address.')
      } else {
        const detail = err?.response?.data?.detail
        setError(detail || 'Registration failed. Please try again.')
      }
    } finally {
      setSubmitting(false)
    }
  }

  // ── Success state ──────────────────────────────────────────────────────────
  if (success) {
    return (
      <div className="relative min-h-screen bg-[#F7F7F7] text-[#111827]">
        <div className="mx-auto flex min-h-screen max-w-6xl items-center justify-center px-6 py-12">
          <div className="w-full max-w-md rounded-2xl border border-[#E5E7EB] bg-white p-8 text-center shadow-sm">
            <div className="text-4xl">✅</div>
            <div className="mt-4 text-lg font-extrabold text-[#111827]">Registration Successful</div>
            <div className="mt-2 text-sm font-semibold text-[#6B7280]">
              Your hospital has been registered. Redirecting to login…
            </div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="relative min-h-screen bg-[#F7F7F7] text-[#111827]">
      <div className="mx-auto flex min-h-screen max-w-6xl items-center justify-center px-6 py-12">
        <div className="w-full max-w-md rounded-2xl border border-[#E5E7EB] bg-white p-8 shadow-sm">
          <div className="space-y-2 text-center">
            <BloodLinkLogo />
            <div className="text-xs font-semibold tracking-[0.2em] text-[#6B7280]">
              HOSPITAL REGISTRATION
            </div>
          </div>

          {/* ── Tabs ── */}
          <div className="mt-6 rounded-full bg-[#F7F7F7] p-1">
            <div className="flex items-center justify-center gap-2">
              <TabButton active={false} onClick={() => navigate('/login')}>
                Login
              </TabButton>
              <TabButton active onClick={() => {}}>
                Register
              </TabButton>
            </div>
          </div>

          <form onSubmit={onSubmit} className="mt-6 space-y-4">

            {/* ── Account ── */}
            <div className="text-xs font-bold tracking-[0.15em] text-[#6B7280]">
              ACCOUNT CREDENTIALS
            </div>

            <Field label="PROFESSIONAL EMAIL">
              <Input
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@your-hospital.org"
                type="email"
                autoComplete="email"
              />
            </Field>

            <Field label="PASSWORD">
              <Input
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Min. 6 characters"
                type="password"
                autoComplete="new-password"
              />
            </Field>

            <Field label="CONFIRM PASSWORD">
              <Input
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                placeholder="Repeat password"
                type="password"
                autoComplete="new-password"
              />
            </Field>

            {/* ── Hospital Details ── */}
            <div className="pt-2 text-xs font-bold tracking-[0.15em] text-[#6B7280]">
              FACILITY DETAILS
            </div>

            <Field label="HOSPITAL NAME">
              <Input
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="City General Hospital"
              />
            </Field>

            <Field label="PHONE NUMBER">
              <Input
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="9999999999"
                type="tel"
              />
            </Field>

            <Field label="CITY">
              <Input
                value={city}
                onChange={(e) => setCity(e.target.value)}
                placeholder="Mumbai"
              />
            </Field>

            <Field label="ADDRESS">
              <Input
                value={address}
                onChange={(e) => setAddress(e.target.value)}
                placeholder="123 Main Street, Mumbai"
              />
            </Field>

            <Field label="REGISTRATION NUMBER (OPTIONAL)">
              <Input
                value={registrationNo}
                onChange={(e) => setRegistrationNo(e.target.value)}
                placeholder="MH-HOSP-2024-XXXX"
              />
            </Field>

            {error && (
              <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={!canSubmit || submitting}
              className="w-full rounded-xl bg-[#C8102E] px-4 py-3 text-sm font-semibold text-white shadow-sm disabled:cursor-not-allowed disabled:opacity-60"
            >
              {submitting ? 'Registering…' : 'Register Hospital →'}
            </button>
          </form>

          <p className="mt-6 text-center text-xs text-[#6B7280]">
            Already registered?{' '}
            <button
              type="button"
              onClick={() => navigate('/login')}
              className="font-semibold text-[#C8102E] hover:underline"
            >
              Sign in to your dashboard
            </button>
          </p>

          <div className="mt-6 flex items-center justify-center gap-4 text-xs text-[#6B7280]">
            <button type="button" className="hover:text-[#111827] hover:underline">Privacy Protocols</button>
            <span>•</span>
            <button type="button" className="hover:text-[#111827] hover:underline">System Status</button>
            <span>•</span>
            <button type="button" className="hover:text-[#111827] hover:underline">Technical Support</button>
          </div>
        </div>
      </div>
    </div>
  )
}