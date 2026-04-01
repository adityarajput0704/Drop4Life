import { api } from './axios'

export async function adminListHospitals({ page = 1, pageSize = 10, search } = {}) {
  const params = { page, page_size: pageSize }
  if (search) params.search = search

  const res = await api.get('/hospitals/', { params })
  return res.data
}

