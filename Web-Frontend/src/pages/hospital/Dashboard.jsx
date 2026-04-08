import { useEffect, useMemo, useState, useCallback } from 'react'
import PageLayout from '../../components/PageLayout.jsx'
import BloodBadge from '../../components/BloodBadge.jsx'
import StatusBadge from '../../components/StatusBadge.jsx'
import UrgencyBadge from '../../components/UrgencyBadge.jsx'
import Pagination from '../../components/Pagination.jsx'
import LoadingSpinner from '../../components/LoadingSpinner.jsx'
import RequestDetailModal from '../../components/RequestDetailModal.jsx'
import { getBloodRequests } from '../../api/requests'
import { formatDateTime } from '../../utils/helpers'
import { useWebSocket } from '../../hooks/useWebSockets.js'
import { useAuth } from '../../context/AuthContext.jsx'

function StatCard({ title, value }) {
  return (
    <div className="rounded-2xl border border-[#E5E7EB] bg-white p-5 shadow-sm">
      <div className="text-xs font-semibold tracking-[0.18em] text-[#6B7280]">{title}</div>
      <div className="mt-2 text-3xl font-extrabold text-[#111827]">{value}</div>
    </div>
  )
}

export default function Dashboard() {
  const [page, setPage] = useState(1)
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [selectedRequest, setSelectedRequest] = useState(null)

  const { profile } = useAuth()
  const room = profile?.id ? `hospital_${profile.id}` : null

  const handleWsEvent = useCallback((event) => {
    const messages = {
      REQUEST_ACCEPTED:  `✅ Donor assigned: ${event.payload?.donor_name}`,
      REQUEST_FULFILLED: `💉 Donation fulfilled — thank you!`,
    }
    const message = messages[event.type]
    if (message) {
      window.dispatchEvent(new CustomEvent('app:toast', {
        detail: { type: 'success', message },
      }))
    }
    if (['REQUEST_ACCEPTED', 'REQUEST_FULFILLED'].includes(event.type)) {
      setPage(1)
    }
  }, [])

  useWebSocket(room, handleWsEvent)

  function fetchData(p = page) {
    setLoading(true)
    setError(null)
    // Fetch ALL requests (public endpoint — no auth filter)
    getBloodRequests({ page: p, pageSize: 10 })
      .then(setData)
      .catch(setError)
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    let alive = true
    setLoading(true)
    setError(null)

    getBloodRequests({ page, pageSize: 10 })
      .then((d) => { if (alive) setData(d) })
      .catch((e) => { if (alive) setError(e) })
      .finally(() => { if (alive) setLoading(false) })

    return () => { alive = false }
  }, [page])

  const stats = useMemo(() => {
    const items = data?.items || []
    const open = items.filter((r) => String(r.status || '').toUpperCase() === 'OPEN').length
    const accepted = items.filter((r) => String(r.status || '').toUpperCase() === 'ACCEPTED').length
    const fulfilled = items.filter((r) => String(r.status || '').toUpperCase() === 'FULFILLED').length
    return { open, accepted, fulfilled }
  }, [data])

  return (
    <PageLayout>
      {loading ? <LoadingSpinner /> : null}
      {error ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-5 py-4 text-sm font-semibold text-red-700">
          Failed to load dashboard data.
        </div>
      ) : null}

      {!loading && !error ? (
        <div className="space-y-6">
          <div className="grid gap-4 md:grid-cols-3">
            <StatCard title="OPEN REQUESTS" value={stats.open} />
            <StatCard title="ACCEPTED" value={stats.accepted} />
            <StatCard title="FULFILLED" value={stats.fulfilled} />
          </div>

          <div className="rounded-2xl border border-[#E5E7EB] bg-white shadow-sm">
            <div className="border-b border-[#E5E7EB] px-6 py-4">
              <div className="text-sm font-bold text-[#111827]">All Blood Requests</div>
              <div className="text-xs font-semibold text-[#6B7280] mt-0.5">Live feed from all hospitals</div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full min-w-200">
                <thead>
                  <tr className="bg-[#F9FAFB] text-left text-xs font-semibold text-[#6B7280]">
                    <th className="px-6 py-3">HOSPITAL</th>
                    <th className="px-6 py-3">GROUP</th>
                    <th className="px-6 py-3">UNITS</th>
                    <th className="px-6 py-3">PATIENT / URGENCY</th>
                    <th className="px-6 py-3">STATUS</th>
                    <th className="px-6 py-3">ACTION</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E5E7EB]">
                  {(data?.items || []).map((r) => (
                    <tr key={r.id} className="text-sm text-[#111827]">
                      <td className="px-6 py-4 font-semibold">{r.hospital_name || '-'}</td>
                      <td className="px-6 py-4">
                        <BloodBadge group={r.blood_group} />
                      </td>
                      <td className="px-6 py-4 font-semibold">{r.units_needed || '-'}</td>
                      <td className="px-6 py-4">
                        <div className="flex flex-col gap-1">
                          <div className="font-semibold">{r.patient_name || '-'}</div>
                          <div className="flex items-center gap-2">
                            <UrgencyBadge level={r.urgency} />
                            <span className="text-xs font-semibold text-[#6B7280]">
                              {formatDateTime(r.created_at)}
                            </span>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <StatusBadge status={r.status} />
                      </td>
                      <td className="px-6 py-4">
                        {/* View only — no actions from dashboard */}
                        <button
                          type="button"
                          onClick={() => setSelectedRequest(r)}
                          className="rounded-lg border border-[#E5E7EB] bg-white px-3 py-2 text-sm font-semibold text-[#111827] hover:bg-[#F7F7F7]"
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

      {/* View-only modal — no cancel, no fulfill */}
      {selectedRequest && (
        <RequestDetailModal
          request={selectedRequest}
          onClose={() => setSelectedRequest(null)}
          showCancel={false}
          showAdminCancel={false}
        />
      )}
    </PageLayout>
  )
}