import { useEffect, useMemo, useState } from 'react'
import PageLayout from '../../components/PageLayout.jsx'
import LoadingSpinner from '../../components/LoadingSpinner.jsx'
import Pagination from '../../components/Pagination.jsx'
import { adminListHospitals } from '../../api/hospitals'

function VerifiedBadge({ value }) {
  const verified = value === true
  return (
    <span
      className={[
        'inline-flex items-center rounded-full px-3 py-1 text-xs font-bold',
        verified ? 'bg-[#F0FDF4] text-[#15803D]' : 'bg-[#F9FAFB] text-[#6B7280]',
      ].join(' ')}
    >
      {verified ? 'VERIFIED' : 'PENDING'}
    </span>
  )
}

function Toggle({ enabled }) {
  return (
    <div
      className={[
        'relative h-7 w-12 rounded-full border border-[#E5E7EB] bg-[#F9FAFB]',
        enabled ? 'bg-[#C8102E]/10' : '',
      ].join(' ')}
    >
      <div
        className={[
          'absolute top-1 h-5 w-5 rounded-full',
          enabled ? 'right-1 bg-[#C8102E]' : 'left-1 bg-[#6B7280]',
        ].join(' ')}
      />
    </div>
  )
}

function StatCard({ title, value, variant }) {
  const style =
    variant === 'red'
      ? 'border-transparent bg-[#C8102E] text-white'
      : 'border-[#E5E7EB] bg-white text-[#111827]'

  return (
    <div className={`rounded-2xl border p-5 shadow-sm ${style}`}>
      <div className={`text-xs font-semibold tracking-[0.18em] ${variant === 'red' ? 'text-white/80' : 'text-[#6B7280]'}`}>
        {title}
      </div>
      <div className="mt-2 text-2xl font-extrabold">{value ?? '-'}</div>
    </div>
  )
}

export default function Hospitals() {
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')

  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    let alive = true
    setLoading(true)
    setError(null)

    adminListHospitals({ page, pageSize: 10, search: search.trim() || undefined })
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
  }, [page, search])

  const items = data?.items || []

  const stats = useMemo(() => {
    const total = data?.total ?? items.length
    const verificationPending = items.filter((h) => h?.verified === false).length
    return { total, verificationPending }
  }, [data, items])

  return (
    <PageLayout>
      <div className="space-y-5">
        <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <div className="text-xl font-extrabold text-[#111827]">Registered Hospitals</div>
            <div className="mt-1 text-sm font-semibold text-[#6B7280]">Manage hospital access and verification.</div>
          </div>

          <div className="flex w-full flex-col gap-3 md:w-auto md:flex-row md:items-center">
            <input
              value={search}
              onChange={(e) => {
                setSearch(e.target.value)
                setPage(1)
              }}
              placeholder="Search hospitals…"
              className="h-11 w-full rounded-xl border border-[#E5E7EB] bg-white px-4 text-sm font-semibold text-[#111827] outline-none focus:border-[#C8102E] md:w-[280px]"
            />
            <button
              type="button"
              className="h-11 rounded-xl bg-[#C8102E] px-4 text-sm font-semibold text-white shadow-sm"
            >
              Register Hospital
            </button>
          </div>
        </div>

        <div className="grid gap-4 lg:grid-cols-2">
          <StatCard title="GLOBAL COVERAGE" value={stats.total} />
          <StatCard title="VERIFICATION PENDING" value={stats.verificationPending} variant="red" />
        </div>

        {loading ? <LoadingSpinner /> : null}
        {error ? (
          <div className="rounded-2xl border border-red-200 bg-red-50 px-5 py-4 text-sm font-semibold text-red-700">
            Failed to load hospitals.
          </div>
        ) : null}

        {!loading && !error ? (
          <div className="rounded-2xl border border-[#E5E7EB] bg-white shadow-sm">
            <div className="overflow-x-auto">
              <table className="w-full min-w-[980px]">
                <thead>
                  <tr className="bg-[#F9FAFB] text-left text-xs font-semibold text-[#6B7280]">
                    <th className="px-6 py-3">HOSPITAL NAME</th>
                    <th className="px-6 py-3">CITY</th>
                    <th className="px-6 py-3">PHONE</th>
                    <th className="px-6 py-3">VERIFIED</th>
                    <th className="px-6 py-3">STATUS</th>
                    <th className="px-6 py-3">ACTIONS</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E5E7EB]">
                  {items.map((h) => (
                    <tr key={h.id || h.ref_id} className="text-sm text-[#111827]">
                      <td className="px-6 py-4">
                        <div className="font-semibold">{h.name || h.hospital_name || '-'}</div>
                        <div className="mt-1 text-xs font-semibold text-[#6B7280]">Ref ID: {h.ref_id || h.id || '-'}</div>
                      </td>
                      <td className="px-6 py-4 font-semibold text-[#6B7280]">{h.city || '-'}</td>
                      <td className="px-6 py-4 font-semibold text-[#6B7280]">{h.phone || '-'}</td>
                      <td className="px-6 py-4">
                        <VerifiedBadge value={h.verified} />
                      </td>
                      <td className="px-6 py-4">
                        <Toggle enabled={Boolean(h.active ?? h.is_active ?? true)} />
                      </td>
                      <td className="px-6 py-4">
                        <button
                          type="button"
                          className="rounded-lg border border-[#E5E7EB] bg-white px-3 py-2 text-sm font-semibold text-[#111827] hover:bg-[#F7F7F7]"
                        >
                          ⋯
                        </button>
                      </td>
                    </tr>
                  ))}
                  {items.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="px-6 py-10 text-center text-sm font-semibold text-[#6B7280]">
                        No hospitals found.
                      </td>
                    </tr>
                  ) : null}
                </tbody>
              </table>
            </div>

            <Pagination response={data} onPageChange={setPage} />
          </div>
        ) : null}
      </div>
    </PageLayout>
  )
}

