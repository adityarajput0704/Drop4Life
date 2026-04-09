import { api } from './axios'

export async function adminListHospitals({ page = 1, pageSize = 10, search } = {}) {
  const params = { page, page_size: pageSize }
  if (search) params.search = search

  const res = await api.get('/hospitals/', { params })
  return res.data
}

export async function verifyHospital(hospitalId) {
  const res = await api.patch(`/hospitals/${hospitalId}/verify`)
  return res.data
}

export async function get_current_hospital(hospitalId) {
  const res = await api.get(`/hospitals/${hospitalId}`)
  return res.data
}