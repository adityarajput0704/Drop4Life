import { useEffect, useMemo, useState } from 'react'
import PageLayout from '../../components/PageLayout.jsx'
import BloodBadge from '../../components/BloodBadge.jsx'
import StatusBadge from '../../components/StatusBadge.jsx'
import UrgencyBadge from '../../components/UrgencyBadge.jsx'
import Pagination from '../../components/Pagination.jsx'
import LoadingSpinner from '../../components/LoadingSpinner.jsx'
import { cancelRequest, getMyRequests } from '../../api/requests'
import { formatDate } from '../../utils/helpers'
import { useCallback } from 'react'
import { useAuth } from '../../context/AuthContext.jsx'
import { useWebSocket } from '../../hooks/useWebSockets.js'
import RequestDetailModal from '../../components/RequestDetailModal.jsx'
import { fulfilRequest } from '../../api/requests'

function FilterTab({ active, onClick, children }) {
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

function BloodSquare({ group }) {
  return (
    <div className="flex h-20 w-20 flex-col items-center justify-center rounded-2xl bg-[#C8102E] text-white shadow-sm">
      <div className="text-[11px] font-bold tracking-[0.2em] opacity-90">BLOOD</div>
      <div className="text-2xl font-extrabold">{group || '-'}</div>
    </div>
  )
}

export default function MyRequests() {
  const [page, setPage] = useState(1)
  const [statusTab, setStatusTab] = useState('ALL')
  const [bloodGroup, setBloodGroup] = useState('')

  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [errorStatus, setErrorStatus] = useState(null)
  const [mutatingId, setMutatingId] = useState(null)
  const [selectedRequest, setSelectedRequest] = useState(null)

  const { profile } = useAuth()
  const room = profile?.id ? `hospital_${profile.id}` : null
  const [refreshTick, setRefreshTick] = useState(0)

  const handleWsEvent = useCallback((event) => {
    const messages = {
      REQUEST_ACCEPTED: `✅ Donor assigned: ${event.payload?.donor_name}`,
      REQUEST_FULFILLED: `💉 Donation marked as fulfilled`,
    }
    const message = messages[event.type]
    if (message) {
      window.dispatchEvent(
        new CustomEvent('app:toast', {
          detail: { type: 'success', message },
        })
      )
    }
    if (['REQUEST_ACCEPTED', 'REQUEST_FULFILLED'].includes(event.type)) {
      setRefreshTick(t => t + 1)
    }
  }, [])

  useWebSocket(room, handleWsEvent)


  const statusParam = useMemo(() => {
    if (statusTab === 'ALL') return undefined
    return statusTab
  }, [statusTab])

  useEffect(() => {
    let alive = true
    setLoading(true)
    setError(null)

    getMyRequests({ page, pageSize: 8, status: statusParam, bloodGroup: bloodGroup || undefined, refreshTick })
      .then((d) => {
        if (!alive) return
        setData(d)
      })
      .catch((e) => {
        if (!alive) return
        setError(e)
        setErrorStatus(e?.response?.status || null)
      })
      .finally(() => {
        if (!alive) return
        setLoading(false)
      })

    return () => {
      alive = false
    }
  }, [page, statusParam, bloodGroup, refreshTick])

  async function onCancel(req) {
    const id = req?.id || req?.request_id
    if (!id) return

    setMutatingId(id)
    try {
      await cancelRequest(id)
      const refreshed = await getMyRequests({
        page,
        pageSize: 8,
        status: statusParam,
        bloodGroup: bloodGroup || undefined,
      })
      setData(refreshed)
    } catch (e) {
      window.dispatchEvent(
        new CustomEvent('app:toast', {
          detail: { type: 'error', message: 'Failed to cancel request. Please try again.' },
        }),
      )
    } finally {
      setMutatingId(null)
    }
  }

  async function onFulfil(req) {
    const id = req?.id || req?.request_id
    if (!id) return

    setMutatingId(id)
    try {
      await fulfilRequest(id, profile.id)

      const refreshed = await getMyRequests({
        page,
        pageSize: 8,
        status: statusParam,
        bloodGroup: bloodGroup || undefined,
      })

      setData(refreshed)

      window.dispatchEvent(
        new CustomEvent('app:toast', {
          detail: { type: 'success', message: 'Request marked as fulfilled.' },
        })
      )
    } catch (e) {
      console.log("FULFIL ERROR:", e?.response?.data)

      const msg = e?.response?.data?.detail || 'Failed to fulfil request.'

      window.dispatchEvent(
        new CustomEvent('app:toast', {
          detail: { type: 'error', message: msg },
        })
      )
    } finally {
      setMutatingId(null)
    }
  }



  const items = data?.items || []

  return (
    <PageLayout>
      <div className="space-y-5">
        <div className="flex flex-col gap-3 rounded-2xl border border-[#E5E7EB] bg-white p-4 shadow-sm md:flex-row md:items-center md:justify-between">
          <div className="rounded-full bg-[#F7F7F7] p-1">
            <div className="flex flex-wrap items-center gap-2">
              <FilterTab
                active={statusTab === 'ALL'}
                onClick={() => {
                  setStatusTab('ALL')
                  setPage(1)
                }}
              >
                All
              </FilterTab>
              <FilterTab
                active={statusTab === 'OPEN'}
                onClick={() => {
                  setStatusTab('OPEN')
                  setPage(1)
                }}
              >
                Open
              </FilterTab>
              <FilterTab
                active={statusTab === 'ACCEPTED'}
                onClick={() => {
                  setStatusTab('ACCEPTED')
                  setPage(1)
                }}
              >
                Accepted
              </FilterTab>
              <FilterTab
                active={statusTab === 'FULFILLED'}
                onClick={() => {
                  setStatusTab('FULFILLED')
                  setPage(1)
                }}
              >
                Fulfilled
              </FilterTab>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <label className="text-sm font-semibold text-[#6B7280]">Blood Group</label>
            <select
              value={bloodGroup}
              onChange={(e) => {
                setBloodGroup(e.target.value)
                setPage(1)
              }}
              className="h-10 rounded-xl border border-[#E5E7EB] bg-white px-3 text-sm font-semibold text-[#111827] outline-none focus:border-[#C8102E]"
            >
              <option value="">All</option>
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
        </div>

        {loading ? <LoadingSpinner /> : null}
        {error ? (
          errorStatus === 403 ? (
            <div className="rounded-2xl border border-amber-200 bg-amber-50 px-6 py-10 text-center shadow-sm">
              <div className="text-3xl">🏥</div>
              <div className="mt-3 text-base font-extrabold text-[#111827]">
                Hospital Not Verified
              </div>
              <div className="mt-2 text-sm font-semibold text-[#6B7280]">
                Your hospital is pending admin verification. Once approved, you'll be able to post and manage blood requests.
              </div>
              <div className="mt-4 inline-block rounded-xl bg-amber-100 px-4 py-2 text-sm font-bold text-amber-700">
                Contact admin to get verified
              </div>
            </div>
          ) : (
            <div className="rounded-2xl border border-red-200 bg-red-50 px-5 py-4 text-sm font-semibold text-red-700">
              Failed to load requests. Please try again.
            </div>
          )
        ) : null}

        {!loading && !error ? (
          <div className="space-y-4">
            {items.map((r) => {
              const id = r?.id || r?.request_id
              const status = String(r?.status || '').toUpperCase()
              const canCancel = status === 'OPEN'
              const canFulfil = status === 'ACCEPTED'

              return (
                <div
                  key={id}
                  className="rounded-2xl border border-[#E5E7EB] bg-white p-5 shadow-sm"
                >
                  <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                    <div className="flex items-start gap-4">
                      <BloodSquare group={r?.blood_group || r?.group} />
                      <div className="space-y-2">
                        <div className="flex flex-wrap items-center gap-2">
                          <div className="text-lg font-extrabold text-[#111827]">
                            {r?.patient_name || r?.patient || '-'}
                          </div>
                          <UrgencyBadge level={r?.urgency || r?.urgency_level} />
                        </div>
                        <div className="flex flex-wrap items-center gap-4 text-sm font-semibold text-[#6B7280]">
                          <div>
                            Units:{' '}
                            <span className="font-bold text-[#111827]">
                              {r?.units || r?.units_needed || '-'}
                            </span>
                          </div>
                          <div>
                            Created:{' '}
                            <span className="font-bold text-[#111827]">{formatDate(r?.created_at)}</span>
                          </div>
                          <div className="hidden md:block">
                            <BloodBadge group={r?.blood_group || r?.group} />
                          </div>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center justify-between gap-3 md:flex-col md:items-end">
                      <StatusBadge status={r?.status} />

                      <div className="flex gap-2">
                        {canCancel && (
                          <button
                            type="button"
                            onClick={() => onCancel(r)}
                            disabled={mutatingId === id}
                            className="rounded-xl bg-[#F9FAFB] px-4 py-2 text-sm font-semibold text-[#111827] ring-1 ring-[#E5E7EB] hover:bg-white disabled:opacity-50"
                          >
                            {mutatingId === id ? 'Cancelling…' : 'Cancel'}
                          </button>
                        )}

                        {canFulfil && (
                          <button
                            type="button"
                            onClick={() => onFulfil(r)}
                            disabled={mutatingId === id}
                            className="rounded-xl bg-green-50 mt-2 px-4 py-2 text-sm font-semibold text-green-700 ring-1 ring-green-200 hover:bg-green-100 disabled:opacity-50"
                          >
                            {mutatingId === id ? 'Processing…' : 'Fulfil'}
                          </button>
                        )}
                      </div>
                    </div>
                  </div>

                  {status === 'ACCEPTED' ? (
                    <div className="mt-3 inline-block rounded-xl border border-[#E5E7EB] bg-[#F9FAFB] px-4 py-3 text-sm">
                      <div className="font-semibold text-[#111827]">Assigned Donor</div>
                      <div className="mt-1 text-sm font-semibold text-[#6B7280]">
                        {r?.assigned_donor?.name || r?.donor_name || '-'} •{' '}
                        {r?.assigned_donor?.phone || r?.donor_phone || '-'}
                      </div>
                    </div>
                  ) : null}
                </div>
              )
            })}

            {items.length === 0 ? (
              <div className="rounded-2xl border border-[#E5E7EB] bg-white px-6 py-12 text-center text-sm font-semibold text-[#6B7280] shadow-sm">
                No requests found.
              </div>
            ) : null}

            <div className="rounded-2xl overflow-hidden">
              <Pagination response={data} onPageChange={setPage} />
            </div>
          </div>
        ) : null}
      </div>
      {selectedRequest && (
        <RequestDetailModal
          request={selectedRequest}
          onClose={() => setSelectedRequest(null)}
          onUpdated={async () => {
            setSelectedRequest(null)
            const refreshed = await getMyRequests({
              page,
              pageSize: 8,
              status: statusParam,
              bloodGroup: bloodGroup || undefined,
            })
            setData(refreshed)
          }}
          showCancel={true}
          showAdminCancel={false}
        />
      )}
    </PageLayout>
  )
}

