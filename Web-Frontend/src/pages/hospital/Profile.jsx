import PageLayout from '../../components/PageLayout.jsx'
import LoadingSpinner from '../../components/LoadingSpinner.jsx'
import { useAuth } from '../../context/AuthContext.jsx'

function Row({ label, value }) {
  return (
    <div className="flex items-center justify-between gap-6 border-b border-[#E5E7EB] py-4">
      <div className="text-sm font-semibold text-[#6B7280]">{label}</div>
      <div className="text-sm font-bold text-[#111827]">{value || '-'}</div>
    </div>
  )
}

export default function Profile() {
  const { profile, loading, error } = useAuth()

  return (
    <PageLayout>
      {loading ? <LoadingSpinner /> : null}
      {error ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-5 py-4 text-sm font-semibold text-red-700">
          Failed to load profile.
        </div>
      ) : null}

      {!loading && !error ? (
        <div className="max-w-3xl rounded-2xl border border-[#E5E7EB] bg-white p-6 shadow-sm">
          <div className="text-lg font-extrabold text-[#111827]">Hospital Profile</div>
          <div className="mt-1 text-sm font-semibold text-[#6B7280]">Account and facility details.</div>

          <div className="mt-6">
            <Row label="Hospital Name" value={profile?.full_name} />
            <Row label="Email" value={profile?.email} />
            <Row label="City" value={profile?.city} />
            <Row label="Phone" value={profile?.phone} />
            <Row label="Reference ID" value={profile?.id} />
            <Row label="Verified" value={profile?.is_verified === true ? 'VERIFIED' : 'PENDING'} />
          </div>
        </div>
      ) : null}
    </PageLayout>
  )
}

