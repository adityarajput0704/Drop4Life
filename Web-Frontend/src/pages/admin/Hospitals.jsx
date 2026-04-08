import { useEffect, useMemo, useState } from 'react'
import PageLayout from '../../components/PageLayout.jsx'
import LoadingSpinner from '../../components/LoadingSpinner.jsx'
import Pagination from '../../components/Pagination.jsx'
import { adminListHospitals, verifyHospital } from '../../api/hospitals'

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

  // Track which hospital IDs are currently being verified (to show loading state)
  const [verifying, setVerifying] = useState(new Set())

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

    return () => { alive = false }
  }, [page, search])

  const items = data?.items || []

  const stats = useMemo(() => {
    const total = data?.total ?? items.length
    // Count unverified hospitals in the current page (reflects optimistic updates)
    const verificationPending = items.filter(
      (h) => h?.verified === false || h?.is_verified === false,
    ).length
    return { total, verificationPending }
  }, [data, items])

  // Optimistically flip the hospital's verified flag in local state,
  // then call the backend. Roll back on failure.
  async function handleVerify(hospitalId) {
    setVerifying((prev) => new Set(prev).add(hospitalId))

    // Optimistic update — flip verified to true immediately
    setData((prev) => {
      if (!prev) return prev
      return {
        ...prev,
        items: prev.items.map((h) =>
          (h.id || h.ref_id) === hospitalId
            ? { ...h, verified: true, is_verified: true }
            : h,
        ),
      }
    })

    try {
      await verifyHospital(hospitalId)
      window.dispatchEvent(new CustomEvent('app:toast', {
        detail: { type: 'success', message: 'Hospital verified successfully.' },
      }))
    } catch {
      // Roll back on error
      setData((prev) => {
        if (!prev) return prev
        return {
          ...prev,
          items: prev.items.map((h) =>
            (h.id || h.ref_id) === hospitalId
              ? { ...h, verified: false, is_verified: false }
              : h,
          ),
        }
      })
      window.dispatchEvent(new CustomEvent('app:toast', {
        detail: { type: 'error', message: 'Failed to verify hospital.' },
      }))
    } finally {
      setVerifying((prev) => {
        const next = new Set(prev)
        next.delete(hospitalId)
        return next
      })
    }
  }

  return (
    <PageLayout>
      <div className="space-y-5">
        <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <div className="text-xl font-extrabold text-[#111827]">Registered Hospitals</div>
            <div className="mt-1 text-sm font-semibold text-[#6B7280]">Hospital registry and verification</div>
          </div>

          <div className="flex w-full flex-col gap-3 md:w-auto md:flex-row md:items-center">
            <input
              value={search}
              onChange={(e) => {
                setSearch(e.target.value)
                setPage(1)
              }}
              placeholder="Search hospitals…"
              className="h-11 w-full rounded-xl border border-[#E5E7EB] bg-white px-4 text-sm font-semibold text-[#111827] outline-none focus:border-[#C8102E] md:w-70"
            />
  
          </div>
        </div>

        {/* Stats — verificationPending updates immediately when a hospital is verified */}
        <div className="grid gap-4 lg:grid-cols-2">
          <StatCard title="Total Hospitals" value={stats.total} />
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
              <table className="w-full min-w-245">
                <thead>
                  <tr className="bg-[#F9FAFB] text-left text-xs font-semibold text-[#6B7280]">
                    <th className="px-6 py-3">HOSPITAL NAME</th>
                    <th className="px-6 py-3">CITY</th>
                    <th className="px-6 py-3">PHONE</th>
                    <th className="px-6 py-3">VERIFIED</th>
                    <th className="px-6 py-3">ACTIONS</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E5E7EB]">
                  {items.map((h) => {
                    const hospitalId = h.id || h.ref_id
                    const isVerified = h.verified === false || h.is_verified === true
                    const isVerifying = verifying.has(hospitalId)

                    return (
                      <tr key={hospitalId} className="text-sm text-[#111827]">
                        <td className="px-6 py-4">
                          <div className="font-semibold">{h.name || h.hospital_name || '-'}</div>
                          <div className="mt-1 text-xs font-semibold text-[#6B7280]">
                            Ref ID: {h.ref_id || h.id || '-'}
                          </div>
                        </td>
                        <td className="px-6 py-4 font-semibold text-[#6B7280]">{h.city || '-'}</td>
                        <td className="px-6 py-4 font-semibold text-[#6B7280]">{h.phone || '-'}</td>
                        <td className="px-6 py-4">
                          {/* Reflects optimistic updates immediately */}
                          <VerifiedBadge value={isVerified} />
                        </td>
                        <td className="px-6 py-4 flex items-center gap-2">
                          {/* Show Verify button only for unverified hospitals */}
                          {!isVerified && (
                            <button
                              type="button"
                              disabled={isVerifying}
                              onClick={() => handleVerify(hospitalId)}
                              className="rounded-xl bg-[#F0FDF4] px-4 py-2 text-sm font-semibold text-[#15803D] ring-1 ring-[#BBF7D0] hover:bg-[#DCFCE7] disabled:cursor-not-allowed disabled:opacity-50"
                            >
                              {isVerifying ? 'Verifying…' : 'Verify'}
                            </button>
                          )}
                          <button
                            type="button"
                            className="rounded-lg border border-[#E5E7EB] bg-white px-3 py-2 text-sm font-semibold text-[#111827] hover:bg-[#F7F7F7]"
                          >
                            ⋯
                          </button>
                        </td>
                      </tr>
                    )
                  })}
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