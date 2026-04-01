import { useEffect, useMemo, useState } from 'react'
import PageLayout from '../../components/PageLayout.jsx'
import LoadingSpinner from '../../components/LoadingSpinner.jsx'
import Pagination from '../../components/Pagination.jsx'
import UrgencyBadge from '../../components/UrgencyBadge.jsx'
import StatusBadge from '../../components/StatusBadge.jsx'
import { adminAllRequests } from '../../api/requests'
import { formatDateTime } from '../../utils/helpers'

function OutlinedBloodBadge({ group }) {
  if (!group) return null
  return (
    <span className="inline-flex items-center rounded-full border border-[#E5E7EB] bg-white px-3 py-1 text-xs font-bold text-[#111827]">
      {group}
    </span>
  )
}

export default function AllRequests() {
  const [page, setPage] = useState(1)
  const [city, setCity] = useState('')
  const [status, setStatus] = useState('')
  const [bloodGroup, setBloodGroup] = useState('')

  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const query = useMemo(
    () => ({
      page,
      pageSize: 10,
      city: city.trim() || undefined,
      status: status || undefined,
      bloodGroup: bloodGroup || undefined,
    }),
    [page, city, status, bloodGroup],
  )

  useEffect(() => {
    let alive = true
    setLoading(true)
    setError(null)

    adminAllRequests(query)
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
  }, [query])

  const items = data?.items || []

  const bottomStats = useMemo(() => {
    const total = items.length
    const fulfilled = items.filter((r) => String(r?.status || '').toUpperCase() === 'FULFILLED').length
    const fulfillmentRate = total === 0 ? 0 : Math.round((fulfilled / total) * 100)

    const open = items.filter((r) => String(r?.status || '').toUpperCase() === 'OPEN')
    const avgMinutes =
      open.length === 0
        ? 0
        : Math.round(
            open.reduce((sum, r) => {
              const d = new Date(r?.created_at)
              if (Number.isNaN(d.getTime())) return sum
              return sum + (Date.now() - d.getTime()) / 60000
            }, 0) / open.length,
          )

    const urgentAlerts = items.filter((r) => String(r?.urgency || r?.urgency_level || '').toUpperCase() === 'CRITICAL').length

    return { avgMinutes, fulfillmentRate, urgentAlerts }
  }, [items])

  function clearFilters() {
    setCity('')
    setStatus('')
    setBloodGroup('')
    setPage(1)
  }

  return (
    <PageLayout>
      <div className="space-y-5">
        <div className="rounded-2xl border border-[#E5E7EB] bg-white p-4 shadow-sm">
          <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
            <div className="flex flex-1 flex-col gap-3 md:flex-row md:items-center">
              <input
                value={city}
                onChange={(e) => {
                  setCity(e.target.value)
                  setPage(1)
                }}
                placeholder="Search city…"
                className="h-11 w-full rounded-xl border border-[#E5E7EB] bg-white px-4 text-sm font-semibold text-[#111827] outline-none focus:border-[#C8102E] md:max-w-[260px]"
              />
              <select
                value={status}
                onChange={(e) => {
                  setStatus(e.target.value)
                  setPage(1)
                }}
                className="h-11 w-full rounded-xl border border-[#E5E7EB] bg-white px-3 text-sm font-semibold text-[#111827] outline-none focus:border-[#C8102E] md:max-w-[220px]"
              >
                <option value="">Status (All)</option>
                <option value="OPEN">OPEN</option>
                <option value="ACCEPTED">ACCEPTED</option>
                <option value="FULFILLED">FULFILLED</option>
                <option value="CANCELLED">CANCELLED</option>
              </select>
              <select
                value={bloodGroup}
                onChange={(e) => {
                  setBloodGroup(e.target.value)
                  setPage(1)
                }}
                className="h-11 w-full rounded-xl border border-[#E5E7EB] bg-white px-3 text-sm font-semibold text-[#111827] outline-none focus:border-[#C8102E] md:max-w-[220px]"
              >
                <option value="">Blood Group (All)</option>
                <option value="A+">A+</option>
                <option value="A-">A-</option>
                <option value="B+">B+</option>
                <option value="B-">B-</option>
                <option value="AB+">AB+</option>
                <option value="AB-">AB-</option>
                <option value="O+">O+</option>
                <option value="O-">O-</option>
              </select>
            </div>

            <button
              type="button"
              onClick={clearFilters}
              className="h-11 rounded-xl bg-[#C8102E] px-4 text-sm font-semibold text-white shadow-sm"
            >
              Clear All Filters
            </button>
          </div>
        </div>

        {loading ? <LoadingSpinner /> : null}
        {error ? (
          <div className="rounded-2xl border border-red-200 bg-red-50 px-5 py-4 text-sm font-semibold text-red-700">
            Failed to load requests.
          </div>
        ) : null}

        {!loading && !error ? (
          <div className="space-y-5">
            <div className="rounded-2xl border border-[#E5E7EB] bg-white shadow-sm">
              <div className="overflow-x-auto">
                <table className="w-full min-w-[980px]">
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
                    {items.map((r) => {
                      const statusText = String(r?.status || '').toUpperCase()
                      const disabled = statusText === 'CANCELLED' || statusText === 'FULFILLED'
                      return (
                        <tr key={r.id || r.request_id} className="text-sm text-[#111827]">
                          <td className="px-6 py-4 font-semibold">{r.hospital_name || r.hospital || '-'}</td>
                          <td className="px-6 py-4">
                            <OutlinedBloodBadge group={r.blood_group || r.group} />
                          </td>
                          <td className="px-6 py-4">
                            <UrgencyBadge level={r.urgency || r.urgency_level} />
                          </td>
                          <td className="px-6 py-4">
                            <StatusBadge status={r.status} withDot />
                          </td>
                          <td className="px-6 py-4 text-[#6B7280] font-semibold">{formatDateTime(r.created_at)}</td>
                          <td className="px-6 py-4">
                            <button
                              type="button"
                              disabled={disabled}
                              className="rounded-xl bg-[#F9FAFB] px-4 py-2 text-sm font-semibold text-[#111827] ring-1 ring-[#E5E7EB] disabled:cursor-not-allowed disabled:opacity-50"
                            >
                              CANCEL
                            </button>
                          </td>
                        </tr>
                      )
                    })}
                    {items.length === 0 ? (
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

            <div className="grid gap-4 lg:grid-cols-3">
              <div className="rounded-2xl border border-[#E5E7EB] bg-white p-5 shadow-sm">
                <div className="text-xs font-semibold tracking-[0.18em] text-[#6B7280]">AVERAGE RESPONSE TIME</div>
                <div className="mt-2 text-2xl font-extrabold text-[#111827]">{bottomStats.avgMinutes}m</div>
              </div>
              <div className="rounded-2xl border border-[#E5E7EB] bg-white p-5 shadow-sm">
                <div className="text-xs font-semibold tracking-[0.18em] text-[#6B7280]">STOCK FULFILLMENT RATE</div>
                <div className="mt-2 text-2xl font-extrabold text-[#111827]">{bottomStats.fulfillmentRate}%</div>
              </div>
              <div className="rounded-2xl border border-transparent bg-[#C8102E] p-5 shadow-sm text-white">
                <div className="text-xs font-semibold tracking-[0.18em] text-white/80">URGENT ALERTS</div>
                <div className="mt-2 text-2xl font-extrabold">{bottomStats.urgentAlerts}</div>
              </div>
            </div>
          </div>
        ) : null}
      </div>
    </PageLayout>
  )
}

