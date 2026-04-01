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
  const res = await api.post('/blood-requests/', payload)
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

