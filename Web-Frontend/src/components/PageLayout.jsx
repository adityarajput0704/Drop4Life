import Sidebar from './Sidebar.jsx'
import Topbar from './Topbar.jsx'

export default function PageLayout({ children }) {
  return (
    <div className="flex min-h-screen bg-[#F7F7F7] text-[#111827]">
      <Sidebar />
      <div className="flex flex-1 flex-col">
        <Topbar />
        <main className="flex-1 p-6">{children}</main>
      </div>
    </div>
  )
}

