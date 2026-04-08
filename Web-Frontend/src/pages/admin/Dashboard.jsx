import { useEffect, useMemo, useState, useCallback } from 'react'
import PageLayout from '../../components/PageLayout.jsx'
import LoadingSpinner from '../../components/LoadingSpinner.jsx'
import Pagination from '../../components/Pagination.jsx'
import BloodBadge from '../../components/BloodBadge.jsx'
import UrgencyBadge from '../../components/UrgencyBadge.jsx'
import StatusBadge from '../../components/StatusBadge.jsx'
import RequestDetailModal from '../../components/RequestDetailModal.jsx'
import { adminAllRequests } from '../../api/requests'
import { listDonors } from '../../api/donors'
import { adminListHospitals } from '../../api/hospitals'
import { formatDateTime } from '../../utils/helpers'
import { useWebSocket } from '../../hooks/useWebSockets.js'

function StatCard({ title, value, variant }) {
  const base = 'rounded-2xl border border-[#E5E7EB] p-5 shadow-sm'
  const style =
    variant === 'red'
      ? 'bg-[#C8102E] text-white border-transparent'
      : 'bg-white text-[#111827]'

  return (
    <div className={`${base} ${style}`}>
      <div className={`text-xs font-semibold tracking-[0.18em] ${variant === 'red' ? 'text-white/80' : 'text-[#6B7280]'}`}>
        {title}
      </div>
      <div className="mt-2 text-3xl font-extrabold">{value}</div>
    </div>
  )
}

export default function Dashboard() {
  const [page, setPage] = useState(1)
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const [donorStats, setDonorStats] = useState({ total: null })
  const [hospitalStats, setHospitalStats] = useState({ total: null })
  const [refreshTick, setRefreshTick] = useState(0)

  // Selected request for the detail modal
  const [selectedRequest, setSelectedRequest] = useState(null)

  // ── WebSocket — real-time events ─────────────────────────────────────────
  const handleWsEvent = useCallback((event) => {
    const messages = {
      REQUEST_CREATED:  `🩸 New request: ${event.payload?.blood_group} — ${event.payload?.hospital_name}`,
      REQUEST_ACCEPTED: `✅ Request accepted by ${event.payload?.donor_name}`,
      REQUEST_FULFILLED:`💉 Donation fulfilled at ${event.payload?.hospital_name}`,
    }
    const message = messages[event.type]
    if (message) {
      window.dispatchEvent(new CustomEvent('app:toast', {
        detail: { type: 'success', message },
      }))
    }
    if (['REQUEST_CREATED', 'REQUEST_ACCEPTED', 'REQUEST_FULFILLED'].includes(event.type)) {
      setRefreshTick(t => t + 1)
    }
  }, [])

  useWebSocket('admin', handleWsEvent)

  // ── Data fetching ─────────────────────────────────────────────────────────
  useEffect(() => {
    let alive = true
    setLoading(true)
    setError(null)

    Promise.all([
      adminAllRequests({ page, pageSize: 10 }),
      listDonors({ page: 1, pageSize: 1 }),
      adminListHospitals({ page: 1, pageSize: 1 }),
    ])
      .then(([requests, donors, hospitals]) => {
        if (!alive) return
        setData(requests)
        setDonorStats({ total: donors?.total ?? null })
        setHospitalStats({ total: hospitals?.total ?? null })
      })
      .catch((e) => {
        if (!alive) return
        setError(e)
      })
      .finally(() => {
        if (!alive) return
        setLoading(false)
      })

    return () => { alive = false }
  }, [page, refreshTick])

  // ── Stats ─────────────────────────────────────────────────────────────────
  const stats = useMemo(() => {
    const totalRequests = data?.total ?? (data?.items || []).length
    const totalDonors = donorStats.total
    const totalHospitals = hospitalStats.total

    const items = data?.items || []
    const today = new Date()
    const fulfilledToday = items.filter((r) => {
      if (String(r?.status || '').toUpperCase() !== 'FULFILLED') return false
      const d = new Date(r?.fulfilled_at || r?.updated_at || r?.created_at)
      if (Number.isNaN(d.getTime())) return false
      return (
        d.getFullYear() === today.getFullYear() &&
        d.getMonth() === today.getMonth() &&
        d.getDate() === today.getDate()
      )
    }).length

    return { totalRequests, totalDonors, totalHospitals, fulfilledToday }
  }, [data, donorStats.total, hospitalStats.total])

  // ── After modal cancel / update — refresh table ───────────────────────────
  function handleRequestUpdated() {
    setSelectedRequest(null)
    adminAllRequests({ page, pageSize: 10 }).then(setData)
  }

  return (
    <PageLayout>
      {loading ? <LoadingSpinner /> : null}
      {error ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-5 py-4 text-sm font-semibold text-red-700">
          Failed to load admin overview.
        </div>
      ) : null}

      {!loading && !error ? (
        <div className="space-y-6">
          {/* Stat cards */}
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
            <StatCard title="TOTAL REQUESTS"  value={stats.totalRequests  ?? '-'} />
            <StatCard title="TOTAL DONORS"    value={stats.totalDonors    ?? '-'} />
            <StatCard title="TOTAL HOSPITALS" value={stats.totalHospitals ?? '-'} />
            <StatCard title="FULFILLED TODAY" value={stats.fulfilledToday ?? '-'} variant="red" />
          </div>

          {/* Requests table */}
          <div className="rounded-2xl border border-[#E5E7EB] bg-white shadow-sm">
            <div className="flex flex-col gap-3 border-b border-[#E5E7EB] px-6 py-4 md:flex-row md:items-center md:justify-between">
              <div className="text-sm font-bold text-[#111827]">Active Requests</div>
              <div className="flex items-center gap-2 text-sm font-semibold text-[#6B7280]">
                Showing latest page from admin feed
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full min-w-245">
                <thead>
                  <tr className="bg-[#F9FAFB] text-left text-xs font-semibold text-[#6B7280]">
                    <th className="px-6 py-3">HOSPITAL</th>
                    <th className="px-6 py-3">BLOOD GROUP</th>
                    <th className="px-6 py-3">URGENCY</th>
                    <th className="px-6 py-3">STATUS</th>
                    <th className="px-6 py-3">CREATED AT</th>
                    <th className="px-6 py-3">ACTIONS</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E5E7EB]">
                  {(data?.items || []).map((r) => (
                    <tr key={r.id || r.request_id} className="text-sm text-[#111827]">
                      <td className="px-6 py-4 font-semibold">{r.hospital_name || r.hospital || '-'}</td>
                      <td className="px-6 py-4">
                        <BloodBadge group={r.blood_group || r.group} />
                      </td>
                      <td className="px-6 py-4">
                        <UrgencyBadge level={r.urgency || r.urgency_level} />
                      </td>
                      <td className="px-6 py-4">
                        <StatusBadge status={r.status} />
                      </td>
                      <td className="px-6 py-4 text-[#6B7280] font-semibold">
                        {formatDateTime(r.created_at)}
                      </td>
                      <td className="px-6 py-4">
                        {/* View — opens RequestDetailModal with admin cancel ability */}
                        <button
                          type="button"
                          onClick={() => setSelectedRequest(r)}
                          className="rounded-xl bg-[#F9FAFB] px-4 py-2 text-sm font-semibold text-[#111827] ring-1 ring-[#E5E7EB] hover:bg-white"
                        >
                          View
                        </button>
                      </td>
                    </tr>
                  ))}
                  {(data?.items || []).length === 0 ? (
                    <tr>
                      <td colSpan={6} className="px-6 py-10 text-center text-sm font-semibold text-[#6B7280]">
                        No requests found.
                      </td>
                    </tr>
                  ) : null}
                </tbody>
              </table>
            </div>

            <Pagination response={data} onPageChange={setPage} />
          </div>
        </div>
      ) : null}

      {/* Request detail modal — showAdminCancel enables the cancel button inside modal */}
      {selectedRequest && (
        <RequestDetailModal
          request={selectedRequest}
          onClose={() => setSelectedRequest(null)}
          onUpdated={handleRequestUpdated}
          showAdminCancel={true}
        />
      )}
    </PageLayout>
  )
}