import { NavLink, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext.jsx'

function Logo({ subtitle }) {
  return (
    <div className="flex items-center gap-2 px-5 py-5">
      <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-[#C8102E] text-white">
        <span className="text-lg font-bold">🩸</span>
      </div>
      <div className="leading-tight">
        <div className="text-lg font-extrabold text-[#C8102E]">Drop4Life</div>
        {subtitle ? <div className="text-xs font-semibold text-[#6B7280]">{subtitle}</div> : null}
      </div>
    </div>
  )
}

function SideLink({ to, children }) {
  return (
    <NavLink
      to={to}
      className={({ isActive }) =>
        [
          'flex items-center justify-between rounded-xl px-4 py-3 text-sm font-semibold',
          isActive ? 'bg-[#F9FAFB] text-[#C8102E]' : 'text-[#6B7280] hover:bg-[#F7F7F7] hover:text-[#111827]',
        ].join(' ')
      }
    >
      {({ isActive }) => (
        <span className="flex items-center gap-3">
          <span className={`h-6 w-1 rounded-full ${isActive ? 'bg-[#C8102E]' : 'bg-transparent'}`} />
          {children}
        </span>
      )}
    </NavLink>
  )
}

export default function Sidebar() {
  const navigate = useNavigate()
  const { role, logout } = useAuth()

  const hospitalLinks = [
    { to: '/hospital/dashboard', label: 'Dashboard' },
    { to: '/hospital/my-requests', label: 'My Requests' },
    { to: '/hospital/create-request', label: 'Create Request' },
    { to: '/hospital/profile', label: 'Profile' },
  ]

  const adminLinks = [
    { to: '/admin/dashboard', label: 'Overview' },
    { to: '/admin/all-requests', label: 'All Requests' },
    { to: '/admin/hospitals', label: 'Hospitals' },
    { to: '/admin/donors', label: 'Donors' },
  ]

  async function onLogout() {
    await logout()
    navigate('/login', { replace: true })
  }

  const links = role === 'admin' ? adminLinks : hospitalLinks
  const subtitle = role === 'admin' ? 'System Admin' : null

  return (
    <aside className="flex h-screen w-70 flex-col border-r border-[#E5E7EB] bg-white">
      <Logo subtitle={subtitle} />

      <nav className="flex-1 px-3">
        <div className="space-y-1">
          {links.map((l) => (
            <SideLink key={l.to} to={l.to}>
              {l.label}
            </SideLink>
          ))}
        </div>
      </nav>

      <div className="space-y-3 p-4">
        {role === 'hospital' ? (
          <NavLink
            to="/hospital/create-request"
            className="block rounded-xl bg-[#C8102E] px-4 py-3 text-center text-sm font-semibold text-white shadow-sm"
          >
            New Urgent Request
          </NavLink>
        ) : null}

        <button
          type="button"
          onClick={onLogout}
          className="w-full rounded-xl border border-[#E5E7EB] bg-white px-4 py-3 text-sm font-semibold text-[#111827] hover:bg-[#F7F7F7]"
        >
          Logout
        </button>
      </div>
    </aside>
  )
}

