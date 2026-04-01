import { useAuth } from '../context/AuthContext.jsx'

function IconButton({ children }) {
  return (
    <button
      type="button"
      className="inline-flex h-10 w-10 items-center justify-center rounded-xl border border-[#E5E7EB] bg-white text-[#6B7280] hover:bg-[#F7F7F7] hover:text-[#111827]"
    >
      {children}
    </button>
  )
}

function BellIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M15 17h5l-1.4-1.4A2 2 0 0 1 18 14.2V11a6 6 0 1 0-12 0v3.2a2 2 0 0 1-.6 1.4L4 17h5" />
      <path d="M9 17a3 3 0 0 0 6 0" />
    </svg>
  )
}

function SettingsIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z" />
      <path d="M19.4 15a7.8 7.8 0 0 0 .1-1l2-1.5-2-3.5-2.4 1a7.7 7.7 0 0 0-1.7-1L15 4h-6l-.4 3a7.7 7.7 0 0 0-1.7 1l-2.4-1-2 3.5 2 1.5a7.8 7.8 0 0 0 .1 1 7.8 7.8 0 0 0-.1 1L2 16.5 4 20l2.4-1a7.7 7.7 0 0 0 1.7 1l.4 3h6l.4-3a7.7 7.7 0 0 0 1.7-1l2.4 1 2-3.5-2-1.5a7.8 7.8 0 0 0-.1-1Z" />
    </svg>
  )
}

function Avatar({ name }) {
  const initials = String(name || '?')
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0]?.toUpperCase())
    .join('')

  return (
    <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#F7F7F7] text-sm font-bold text-[#111827]">
      {initials || '?'}
    </div>
  )
}

export default function Topbar() {
  const { role, profile } = useAuth()

  const displayName =
    profile?.name || profile?.hospital_name || profile?.full_name || profile?.email || 'Dashboard'

  return (
    <header className="flex items-center justify-between border-b border-[#E5E7EB] bg-white px-6 py-4">
      <div className="flex items-center gap-3">
        <div className="text-lg font-bold text-[#111827]">{displayName}</div>
        {role === 'hospital' ? (
          <span className="inline-flex items-center gap-2 rounded-full bg-[#EFF6FF] px-3 py-1 text-xs font-semibold text-[#1D4ED8]">
            <span className="h-2 w-2 rounded-full bg-[#1D4ED8]" />
            Verified
          </span>
        ) : null}
      </div>

      <div className="flex items-center gap-3">
        <IconButton>
          <BellIcon />
        </IconButton>
        <IconButton>
          <SettingsIcon />
        </IconButton>

        <div className="flex items-center gap-3 rounded-xl border border-[#E5E7EB] bg-white px-3 py-2">
          <Avatar name={displayName} />
          <div className="leading-tight">
            <div className="text-sm font-semibold text-[#111827]">{displayName}</div>
            <div className="text-xs font-semibold text-[#6B7280]">{role === 'admin' ? 'Admin' : 'Hospital'}</div>
          </div>
        </div>
      </div>
    </header>
  )
}

