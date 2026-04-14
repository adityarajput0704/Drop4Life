import { useEffect, useRef, useMemo, useState, useCallback } from 'react'
import PageLayout from '../../components/PageLayout.jsx'
import BloodBadge from '../../components/BloodBadge.jsx'
import StatusBadge from '../../components/StatusBadge.jsx'
import UrgencyBadge from '../../components/UrgencyBadge.jsx'
import Pagination from '../../components/Pagination.jsx'
import LoadingSpinner from '../../components/LoadingSpinner.jsx'
import RequestDetailModal from '../../components/RequestDetailModal.jsx'
import { getBloodRequests } from '../../api/requests'
import { getNearbyDonors } from '../../api/donors'
import { formatDateTime } from '../../utils/helpers'
import { useWebSocket } from '../../hooks/useWebSockets.js'
import { useAuth } from '../../context/AuthContext.jsx'
import {api} from '../../api/axios.js'

function StatCard({ title, value }) {
  return (
    <div className="rounded-2xl border border-[#E5E7EB] bg-white p-5 shadow-sm">
      <div className="text-xs font-semibold tracking-[0.18em] text-[#6B7280]">{title}</div>
      <div className="mt-2 text-3xl font-extrabold text-[#111827]">{value}</div>
    </div>
  )
}

function DonorMap({ hospitalLat, hospitalLng }) {
  const mapRef = useRef(null)
  const mapInstanceRef = useRef(null)
  const [donors, setDonors] = useState([])
  const [loading, setLoading] = useState(true)
  const [trackedDonor, setTrackedDonor] = useState(null)

  useEffect(() => {
    if (!hospitalLat || !hospitalLng) return

    const link = document.createElement('link')
    link.rel = 'stylesheet'
    link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css'
    document.head.appendChild(link)

    const script = document.createElement('script')
    script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js'
    script.onload = () => initMap()
    document.head.appendChild(script)

    // ── CLEANUP — runs when component unmounts ──
    return () => {
      if (mapInstanceRef.current) {
        clearInterval(mapInstanceRef.current._refreshInterval)  // ← stop polling
        mapInstanceRef.current.remove()
        mapInstanceRef.current = null
      }
    }
  }, [hospitalLat, hospitalLng])

  async function initMap() {
    if (!mapRef.current || mapInstanceRef.current) return
    const L = window.L

    const map = L.map(mapRef.current).setView([hospitalLat, hospitalLng], 13)
    mapInstanceRef.current = map

    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap contributors',
    }).addTo(map)

    // ── Hospital marker ──
    const hospitalIcon = L.divIcon({
      html: `
        <div style="display:flex;flex-direction:column;align-items:center;gap:2px">
          <div style="
            background:#DC2626;color:white;padding:4px 10px;
            border-radius:20px;font-size:11px;font-weight:700;
            box-shadow:0 2px 8px rgba(220,38,38,0.4);
            white-space:nowrap;border:2px solid white
          ">🏥 Your Hospital</div>
          <div style="
            width:0;height:0;
            border-left:6px solid transparent;
            border-right:6px solid transparent;
            border-top:10px solid #DC2626
          "></div>
        </div>`,
      className: '',
      iconAnchor: [60, 42],
    })

    L.marker([hospitalLat, hospitalLng], { icon: hospitalIcon })
      .addTo(map)
      .bindPopup('<b>Your Hospital</b>')

    // ── Fetch and place donor markers ──
    async function loadDonors() {
      try {
        const data = await getNearbyDonors({
          lat: hospitalLat,
          lng: hospitalLng,
          radiusKm: 50,
        })
        setDonors(data.items || [])

          ; (data.items || []).forEach((donor) => {
            if (!donor.latitude || !donor.longitude) return

            const donorIcon = L.divIcon({
              html: `
              <div style="display:flex;flex-direction:column;align-items:center;gap:2px">
                <div style="
                  background:#1D4ED8;color:white;padding:4px 10px;
                  border-radius:20px;font-size:11px;font-weight:700;
                  box-shadow:0 2px 8px rgba(29,78,216,0.4);
                  white-space:nowrap;border:2px solid white
                ">🩸 ${donor.blood_group} · ${donor.distance_km}km</div>
                <div style="
                  width:0;height:0;
                  border-left:6px solid transparent;
                  border-right:6px solid transparent;
                  border-top:10px solid #1D4ED8
                "></div>
              </div>`,
              className: '',
              iconAnchor: [50, 42],
            })

            L.marker([donor.latitude, donor.longitude], { icon: donorIcon })
              .addTo(map)
              .bindPopup(`
              <b>${donor.full_name}</b><br/>
              Blood: ${donor.blood_group}<br/>
              City: ${donor.city}<br/>
              Distance: ${donor.distance_km} km<br/>
              <span style="color:green;font-weight:bold">Available</span>
            `)
              .on('click', () => setTrackedDonor(donor))
          })
      } catch (e) {
        console.error('Failed to load donors', e)
      } finally {
        setLoading(false)
      }
    }

    await loadDonors()

    // ── Auto-refresh every 30 seconds ──
    const refreshInterval = setInterval(loadDonors, 30000)
    mapInstanceRef.current._refreshInterval = refreshInterval  // store for cleanup
  }

  // Conditional return AFTER all hooks
  if (!hospitalLat || !hospitalLng) {
    return (
      <div className="rounded-2xl border border-[#E5E7EB] bg-white shadow-sm p-8 text-center">
        <div className="text-sm font-bold text-[#111827] mb-2">Nearby Donors Map</div>
        <div className="text-xs text-[#6B7280]">
          Hospital location not set. Click "Set My Location" to enable the map.
        </div>
      </div>
    )
  }

  return (
    <div className="rounded-2xl border border-[#E5E7EB] bg-white shadow-sm overflow-hidden">

      {/* ── Header ── */}
      <div className="border-b border-[#E5E7EB] px-6 py-4 flex items-center justify-between">
        <div>
          <div className="text-sm font-bold text-[#111827]">Nearby Donors</div>
          <div className="mt-1 text-xs font-semibold text-[#6B7280]">
            {loading ? 'Loading...' : `${donors.length} available donors within 50km`}
          </div>
        </div>

        <div className="flex items-center gap-3">
          {trackedDonor && (
            <div className="flex items-center gap-2 rounded-lg bg-blue-50 px-3 py-2 text-xs font-semibold text-blue-700">
              <span className="inline-block h-2 w-2 animate-pulse rounded-full bg-blue-500" />
              Tracking: {trackedDonor.full_name}
            </div>
          )}

          {/* ── Set My Location button ── */}
          <button
            onClick={async () => {
              if (!navigator.geolocation) {
                alert('Geolocation not supported by your browser')
                return
              }
              navigator.geolocation.getCurrentPosition(
                async (pos) => {
                  try {
                    await api.patch('/hospitals/me/location', {
                      latitude: pos.coords.latitude,
                      longitude: pos.coords.longitude,
                    })
                    window.location.reload()
                  } catch (e) {
                    console.error('Failed to update location', e)
                    alert('Failed to save location. Please try again.')
                  }
                },
                (err) => {
                  alert('Could not get your location. Please allow location access.')
                  console.error(err)
                }
              )
            }}
            className="rounded-lg bg-red-50 px-3 py-2 text-xs font-semibold text-red-700 hover:bg-red-100"
          >
            Set My Location
          </button>
        </div>
      </div>

      {/* ── Map container ── */}
      <div ref={mapRef} style={{ height: '420px', width: '100%' }} />

      {/* ── Donor pills below map ── */}
      {donors.length > 0 && (
        <div className="border-t border-[#E5E7EB] px-6 py-3">
          <div className="flex flex-wrap gap-2">
            {donors.slice(0, 5).map((d) => (
              <span
                key={d.id}
                className="rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700"
              >
                {d.full_name} · {d.blood_group} · {d.distance_km}km
              </span>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

export default function Dashboard() {
  const [page, setPage] = useState(1)
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [selectedRequest, setSelectedRequest] = useState(null)

  const { profile, hospital } = useAuth()
  const room = profile?.id ? `hospital_${profile.id}` : null

  const handleWsEvent = useCallback((event) => {
    const messages = {
      REQUEST_ACCEPTED: `✅ Donor assigned: ${event.payload?.donor_name}`,
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

          <DonorMap
            hospitalLat={hospital?.latitude}
            hospitalLng={hospital?.longitude}
          />

          <div className="rounded-2xl border border-[#E5E7EB] bg-white shadow-sm">
            <div className="border-b border-[#E5E7EB] px-6 py-4">
              <div className="text-sm font-bold text-[#111827]">All Blood Requests</div>
              <div className="mt-1 text-xs font-semibold text-[#6B7280]">Recent requests from all hospitals.</div>
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