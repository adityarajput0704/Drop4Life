import { useState } from 'react'
import BloodBadge from './BloodBadge.jsx'
import StatusBadge from './StatusBadge.jsx'
import UrgencyBadge from './UrgencyBadge.jsx'
import { formatDateTime } from '../utils/helpers'
import { cancelRequest, adminCancelRequest } from '../api/requests'

function DetailRow({ label, value }) {
  if (value === null || value === undefined || value === '') return null
  return (
    <div className="flex items-start justify-between gap-4 py-2.5 border-b border-[#F3F4F6] last:border-0">
      <span className="text-xs font-semibold tracking-wide text-[#6B7280] uppercase shrink-0">{label}</span>
      <span className="text-sm font-semibold text-[#111827] text-right">{value}</span>
    </div>
  )
}

/**
 * Props:
 *  request       - the blood request object
 *  onClose       - called when modal should close
 *  onUpdated     - called with updated request after a mutation
 *  showCancel    - whether to show Cancel button (hospital own requests only)
 *  showAdminCancel - whether to show admin Cancel button
 */
export default function RequestDetailModal({
  request: initialRequest,
  onClose,
  onUpdated,
  showCancel = false,
  showAdminCancel = false,
}) {
  const [request, setRequest] = useState(initialRequest)
  const [loading, setLoading] = useState(null)
  const [error, setError] = useState(null)

  const status = String(request?.status || '').toUpperCase()
  const id = request?.id

  // Hospital cancels their own OPEN request
  async function handleCancel() {
    setLoading('cancel')
    setError(null)
    try {
      const updated = await cancelRequest(id)
      setRequest(updated)
      onUpdated?.(updated)
      window.dispatchEvent(new CustomEvent('app:toast', {
        detail: { type: 'success', message: 'Request cancelled successfully.' }
      }))
    } catch (e) {
      const msg = e?.response?.data?.detail || 'Failed to cancel request.'
      setError(msg)
    } finally {
      setLoading(null)
    }
  }

  // Admin cancels any request
  async function handleAdminCancel() {
    setLoading('adminCancel')
    setError(null)
    try {
      const updated = await adminCancelRequest(id)
      setRequest(updated)
      onUpdated?.(updated)
      window.dispatchEvent(new CustomEvent('app:toast', {
        detail: { type: 'success', message: 'Request cancelled by admin.' }
      }))
    } catch (e) {
      const msg = e?.response?.data?.detail || 'Failed to cancel request.'
      setError(msg)
    } finally {
      setLoading(null)
    }
  }

  // Only show cancel if request is still OPEN or ACCEPTED
  const cancelAllowed = showCancel && (status === 'OPEN')
  const adminCancelAllowed = showAdminCancel && (status === 'OPEN' || status === 'ACCEPTED')
  const hasActions = cancelAllowed || adminCancelAllowed

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4"
      style={{ background: 'rgba(0,0,0,0.45)' }}
      onClick={(e) => { if (e.target === e.currentTarget) onClose() }}
    >
      <div className="w-full max-w-lg rounded-2xl bg-white shadow-xl overflow-hidden">

        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-[#E5E7EB]">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 flex-col items-center justify-center rounded-xl bg-[#C8102E] text-white">
              <div className="text-[9px] font-bold tracking-widest opacity-80">BLOOD</div>
              <div className="text-sm font-extrabold leading-none">{request?.blood_group || '-'}</div>
            </div>
            <div>
              <div className="text-base font-extrabold text-[#111827]">{request?.patient_name || '-'}</div>
              <div className="text-xs font-semibold text-[#6B7280]">
                {request?.hospital_name || '-'} · {request?.hospital_city || '-'}
              </div>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="flex h-8 w-8 items-center justify-center rounded-full text-[#6B7280] hover:bg-[#F3F4F6] text-lg font-bold"
          >
            ✕
          </button>
        </div>

        {/* Body */}
        <div className="px-6 py-4 space-y-1 max-h-[60vh] overflow-y-auto">

          {/* Status + Urgency row */}
          <div className="flex items-center gap-3 pb-3 border-b border-[#F3F4F6]">
            <StatusBadge status={request?.status} withDot />
            <UrgencyBadge level={request?.urgency} />
            <BloodBadge group={request?.blood_group} />
          </div>

          {/* Request Details */}
          <div className="pt-2">
            <div className="text-[10px] font-bold tracking-[0.2em] text-[#9CA3AF] uppercase mb-2">
              Request Details
            </div>
            <DetailRow label="Units Needed" value={request?.units_needed} />
            <DetailRow label="Urgency" value={String(request?.urgency || '').toUpperCase()} />
            <DetailRow label="Notes" value={request?.notes} />
            <DetailRow label="Created" value={formatDateTime(request?.created_at)} />
          </div>

          {/* Hospital Info */}
          <div className="pt-3">
            <div className="text-[10px] font-bold tracking-[0.2em] text-[#9CA3AF] uppercase mb-2">
              Hospital
            </div>
            <DetailRow label="Name" value={request?.hospital_name} />
            <DetailRow label="City" value={request?.hospital_city} />
            <DetailRow label="Phone" value={request?.hospital_phone} />
          </div>

          {/* Donor Info — only if accepted or fulfilled */}
          {(status === 'ACCEPTED' || status === 'FULFILLED') && (
            <div className="pt-3">
              <div className="text-[10px] font-bold tracking-[0.2em] text-[#9CA3AF] uppercase mb-2">
                Assigned Donor
              </div>
              <DetailRow label="Name" value={request?.donor_name || '—'} />
              <DetailRow label="Phone" value={request?.donor_phone || '—'} />
            </div>
          )}

          {error && (
            <div className="mt-3 rounded-xl bg-red-50 border border-red-200 px-4 py-2 text-sm font-semibold text-red-700">
              {error}
            </div>
          )}
        </div>

        {/* Footer — only rendered when there are actions */}
        {hasActions && (
          <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-[#E5E7EB] bg-[#F9FAFB]">
            {cancelAllowed && (
              <button
                type="button"
                onClick={handleCancel}
                disabled={!!loading}
                className="rounded-xl border border-[#E5E7EB] bg-white px-5 py-2.5 text-sm font-semibold text-[#111827] hover:bg-[#F9FAFB] disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {loading === 'cancel' ? 'Cancelling…' : 'Cancel Request'}
              </button>
            )}
            {adminCancelAllowed && (
              <button
                type="button"
                onClick={handleAdminCancel}
                disabled={!!loading}
                className="rounded-xl border border-red-200 bg-red-50 px-5 py-2.5 text-sm font-semibold text-red-700 hover:bg-red-100 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {loading === 'adminCancel' ? 'Cancelling…' : 'Cancel Request'}
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  )
}