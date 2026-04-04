import { useEffect, useMemo, useState } from 'react'
import PageLayout from '../../components/PageLayout.jsx'
import BloodBadge from '../../components/BloodBadge.jsx'
import StatusBadge from '../../components/StatusBadge.jsx'
import UrgencyBadge from '../../components/UrgencyBadge.jsx'
import Pagination from '../../components/Pagination.jsx'
import LoadingSpinner from '../../components/LoadingSpinner.jsx'
import { getMyRequests } from '../../api/requests'
import { formatDateTime } from '../../utils/helpers'

function StatCard({ title, value, sub }) {
  return (
    <div className="rounded-2xl border border-[#E5E7EB] bg-white p-5 shadow-sm">
      <div className="text-xs font-semibold tracking-[0.18em] text-[#6B7280]">{title}</div>
      <div className="mt-2 text-3xl font-extrabold text-[#111827]">{value}</div>
      <div className="mt-1 text-sm font-semibold text-[#6B7280]">{sub}</div>
    </div>
  )
}

export default function Dashboard() {
  const [page, setPage] = useState(1)
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    let alive = true
    setLoading(true)
    setError(null)

    getMyRequests({ page, pageSize: 10 })
      .then((d) => {
        if (!alive) return
        setData(d)
      })
      .catch((e) => {
        if (!alive) return
        setError(e)
      })
      .finally(() => {
        if (!alive) return
        setLoading(false)
      })

    return () => {
      alive = false
    }
  }, [page])

  const stats = useMemo(() => {
    const items = data?.items || []
    const active = items.filter((r) => String(r.status || '').toUpperCase() === 'OPEN').length
    const fulfilled = items.filter((r) => String(r.status || '').toUpperCase() === 'FULFILLED').length
    const pending = items.filter((r) => String(r.status || '').toUpperCase() === 'ACCEPTED').length
    const total = items.length

    const today = new Date()
    const isToday = (value) => {
      const d = new Date(value)
      if (Number.isNaN(d.getTime())) return false
      return (
        d.getFullYear() === today.getFullYear() &&
        d.getMonth() === today.getMonth() &&
        d.getDate() === today.getDate()
      )
    }

    const createdToday = items.filter((r) => isToday(r.created_at)).length
    const fulfilledRate = total === 0 ? 0 : Math.round((fulfilled / total) * 100)

    const openCreatedAts = items
      .filter((r) => String(r.status || '').toUpperCase() === 'OPEN')
      .map((r) => new Date(r.created_at))
      .filter((d) => !Number.isNaN(d.getTime()))

    const avgMinutes =
      openCreatedAts.length === 0
        ? 0
        : Math.round(
            openCreatedAts.reduce((sum, d) => sum + (Date.now() - d.getTime()) / 60000, 0) /
              openCreatedAts.length,
          )

    return { active, fulfilled, pending, createdToday, fulfilledRate, avgMinutes }
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
            <StatCard title="ACTIVE REQUESTS" value={stats.active} sub={`+${stats.createdToday} today`} />
            <StatCard title="FULFILLED" value={stats.fulfilled} sub={`${stats.fulfilledRate}% rate`} />
            <StatCard title="PENDING" value={stats.pending} sub={`Avg ${stats.avgMinutes}m`} />
          </div>

          <div className="rounded-2xl border border-[#E5E7EB] bg-white shadow-sm">
            <div className="border-b border-[#E5E7EB] px-6 py-4">
              <div className="text-sm font-bold text-[#111827]">Recent Blood Requests</div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full min-w-225">
                <thead>
                  <tr className="bg-[#F9FAFB] text-left text-xs font-semibold text-[#6B7280]">
                    <th className="px-6 py-3">REQUEST ID</th>
                    <th className="px-6 py-3">GROUP</th>
                    <th className="px-6 py-3">UNITS</th>
                    <th className="px-6 py-3">PATIENT / URGENCY</th>
                    <th className="px-6 py-3">STATUS</th>
                    <th className="px-6 py-3">ACTION</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E5E7EB]">
                  {(data?.items || []).map((r) => (
                    <tr key={r.id || r.request_id} className="text-sm text-[#111827]">
                      <td className="px-6 py-4 font-semibold text-[#111827]">
                        {r.request_id || r.id || '-'}
                      </td>
                      <td className="px-6 py-4">
                        <BloodBadge group={r.blood_group || r.group} />
                      </td>
                      <td className="px-6 py-4 font-semibold">{r.units || r.units_needed || '-'}</td>
                      <td className="px-6 py-4">
                        <div className="flex flex-col gap-1">
                          <div className="font-semibold">{r.patient_name || r.patient || '-'}</div>
                          <div className="flex items-center gap-2">
                            <UrgencyBadge level={r.urgency || r.urgency_level} />
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
                        <button
                          type="button"
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
    </PageLayout>
  )
}

