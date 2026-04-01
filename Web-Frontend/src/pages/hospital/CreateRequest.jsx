import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import PageLayout from '../../components/PageLayout.jsx'
import { createRequest } from '../../api/requests'

function FieldLabel({ children }) {
  return <label className="block text-xs font-semibold text-[#6B7280]">{children}</label>
}

function TextInput({ value, onChange, placeholder, error, type = 'text' }) {
  return (
    <input
      value={value}
      onChange={onChange}
      placeholder={placeholder}
      type={type}
      className={[
        'mt-2 w-full rounded-xl border bg-white px-4 py-3 text-sm outline-none',
        error ? 'border-red-300 focus:border-red-400' : 'border-[#E5E7EB] focus:border-[#C8102E]',
      ].join(' ')}
    />
  )
}

function SelectInput({ value, onChange, children, error }) {
  return (
    <select
      value={value}
      onChange={onChange}
      className={[
        'mt-2 h-11 w-full rounded-xl border bg-white px-3 text-sm font-semibold outline-none',
        error ? 'border-red-300 focus:border-red-400' : 'border-[#E5E7EB] focus:border-[#C8102E]',
      ].join(' ')}
    >
      {children}
    </select>
  )
}

function ErrorText({ children }) {
  if (!children) return null
  return <div className="mt-2 text-sm font-semibold text-red-700">{children}</div>
}

export default function CreateRequest() {
  const navigate = useNavigate()

  const [bloodGroup, setBloodGroup] = useState('')
  const [unitsNeeded, setUnitsNeeded] = useState('')
  const [patientName, setPatientName] = useState('')
  const [urgencyLevel, setUrgencyLevel] = useState('')
  const [notes, setNotes] = useState('')

  const [submitting, setSubmitting] = useState(false)
  const [errors, setErrors] = useState({})

  const canSubmit = useMemo(() => {
    return Boolean(bloodGroup && unitsNeeded && patientName.trim() && urgencyLevel)
  }, [bloodGroup, unitsNeeded, patientName, urgencyLevel])

  function validate() {
    const next = {}
    if (!bloodGroup) next.bloodGroup = 'Blood group is required.'
    if (!unitsNeeded) next.unitsNeeded = 'Units needed is required.'
    if (Number(unitsNeeded) <= 0) next.unitsNeeded = 'Units needed must be greater than 0.'
    if (!patientName.trim()) next.patientName = 'Patient legal name is required.'
    if (!urgencyLevel) next.urgencyLevel = 'Urgency level is required.'
    return next
  }

  async function onSubmit(e) {
    e.preventDefault()
    const nextErrors = validate()
    setErrors(nextErrors)
    if (Object.keys(nextErrors).length > 0) return

    setSubmitting(true)
    try {
      await createRequest({
        blood_group: bloodGroup,
        units_needed: Number(unitsNeeded),
        patient_name: patientName.trim(),
        urgency_level: urgencyLevel,
        notes,
      })
      navigate('/hospital/my-requests', { replace: true })
    } catch (e2) {
      window.dispatchEvent(
        new CustomEvent('app:toast', {
          detail: { type: 'error', message: 'Failed to submit request. Please try again.' },
        }),
      )
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <PageLayout>
      <div className="grid gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <div className="rounded-2xl border border-[#E5E7EB] bg-white p-6 shadow-sm">
            <div className="text-lg font-extrabold text-[#111827]">Create Blood Request</div>
            <div className="mt-1 text-sm font-semibold text-[#6B7280]">
              Submit a new request to the Drop4Life network.
            </div>

            <form onSubmit={onSubmit} className="mt-6 space-y-5">
              <div className="grid gap-5 md:grid-cols-2">
                <div>
                  <FieldLabel>BLOOD GROUP</FieldLabel>
                  <SelectInput
                    value={bloodGroup}
                    onChange={(e) => setBloodGroup(e.target.value)}
                    error={errors.bloodGroup}
                  >
                    <option value="">Select group</option>
                    <option value="A+">A+</option>
                    <option value="A-">A-</option>
                    <option value="B+">B+</option>
                    <option value="B-">B-</option>
                    <option value="AB+">AB+</option>
                    <option value="AB-">AB-</option>
                    <option value="O+">O+</option>
                    <option value="O-">O-</option>
                  </SelectInput>
                  <ErrorText>{errors.bloodGroup}</ErrorText>
                </div>

                <div>
                  <FieldLabel>UNITS NEEDED</FieldLabel>
                  <TextInput
                    value={unitsNeeded}
                    onChange={(e) => setUnitsNeeded(e.target.value)}
                    placeholder="e.g. 2"
                    type="number"
                    error={errors.unitsNeeded}
                  />
                  <ErrorText>{errors.unitsNeeded}</ErrorText>
                </div>
              </div>

              <div>
                <FieldLabel>PATIENT LEGAL NAME</FieldLabel>
                <TextInput
                  value={patientName}
                  onChange={(e) => setPatientName(e.target.value)}
                  placeholder="Full name as per records"
                  error={errors.patientName}
                />
                <ErrorText>{errors.patientName}</ErrorText>
              </div>

              <div>
                <FieldLabel>URGENCY LEVEL</FieldLabel>
                <SelectInput
                  value={urgencyLevel}
                  onChange={(e) => setUrgencyLevel(e.target.value)}
                  error={errors.urgencyLevel}
                >
                  <option value="">Select urgency</option>
                  <option value="CRITICAL">CRITICAL</option>
                  <option value="HIGH">HIGH</option>
                  <option value="MEDIUM">MEDIUM</option>
                  <option value="LOW">LOW</option>
                </SelectInput>
                <ErrorText>{errors.urgencyLevel}</ErrorText>
              </div>

              <div>
                <FieldLabel>MEDICAL NOTES &amp; INSTRUCTIONS</FieldLabel>
                <textarea
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  rows={5}
                  placeholder="Any critical instructions for donors / collection team"
                  className="mt-2 w-full rounded-xl border border-[#E5E7EB] bg-white px-4 py-3 text-sm outline-none focus:border-[#C8102E]"
                />
              </div>

              <button
                type="submit"
                disabled={!canSubmit || submitting}
                className="w-full rounded-xl bg-[#C8102E] px-4 py-3 text-sm font-semibold text-white shadow-sm disabled:cursor-not-allowed disabled:opacity-60"
              >
                {submitting ? 'Submitting…' : 'Submit Request'}
              </button>
            </form>
          </div>
        </div>

        <div className="lg:col-span-1">
          <div className="rounded-2xl border border-[#E5E7EB] bg-white p-6 shadow-sm">
            <div className="text-sm font-extrabold text-[#111827]">Submission Protocol</div>
            <div className="mt-3 space-y-3 text-sm font-semibold text-[#6B7280]">
              <div className="rounded-xl border border-[#E5E7EB] bg-[#F9FAFB] px-4 py-3">
                Confirm patient identity and hospital authorization.
              </div>
              <div className="rounded-xl border border-[#E5E7EB] bg-[#F9FAFB] px-4 py-3">
                Enter accurate blood group and unit requirement.
              </div>
              <div className="rounded-xl border border-[#E5E7EB] bg-[#F9FAFB] px-4 py-3">
                Use CRITICAL only for life-threatening emergencies.
              </div>
              <div className="rounded-xl border border-[#E5E7EB] bg-[#F9FAFB] px-4 py-3">
                Keep notes concise and clinically relevant.
              </div>
            </div>
          </div>
        </div>
      </div>
    </PageLayout>
  )
}

