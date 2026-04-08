import { api } from './axios'

export async function getBloodRequests({ page = 1, pageSize = 10 } = {}) {
  const res = await api.get('/blood-requests', {
    params: { page, page_size: pageSize },
  })
  return res.data
}

export async function getMyRequests({ page = 1, pageSize = 10, status, bloodGroup } = {}) {
  const params = { page, page_size: pageSize }
  if (status) params.status = status
  if (bloodGroup) params.blood_group = bloodGroup

  const res = await api.get('/blood-requests/my-requests', { params })
  return res.data
}

export async function createRequest(payload) {
  const normalized = {
    blood_group:  payload.blood_group,
    units_needed: payload.units_needed,
    patient_name: payload.patient_name,
    urgency:      (payload.urgency_level || payload.urgency || '').toLowerCase(), // ← fix key + case
    notes:        payload.notes || null,
  }
  const res = await api.post('/blood-requests/', normalized)
  return res.data
}

export async function cancelRequest(requestId) {
  const res = await api.post(`/blood-requests/${requestId}/cancel`)
  return res.data
}

export async function adminAllRequests({
  page = 1,
  pageSize = 10,
  city,
  status,
  bloodGroup,
} = {}) {
  const params = { page, page_size: pageSize }
  if (city) params.city = city
  if (status) params.status = status
  if (bloodGroup) params.blood_group = bloodGroup

  const res = await api.get('/blood-requests/admin/all', { params })
  return res.data
}


export async function fulfillRequest(requestId) {
  const res = await api.post(`/blood-requests/${requestId}/fulfil`)
  return res.data
}

export async function getRequestById(requestId) {
  const res = await api.get(`/blood-requests/${requestId}`)
  return res.data
}

export async function adminCancelRequest(requestId) {
  const res = await api.post(`/blood-requests/admin/${requestId}/cancel`)
  return res.data
}