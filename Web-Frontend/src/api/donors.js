import { api } from './axios'

export async function listDonors({ page = 1, pageSize = 10, search, city } = {}) {
  const params = { page, page_size: pageSize }
  if (search) params.search = search
  if (city) params.city = city

  const res = await api.get('/donors/', { params })
  return res.data
}

export async function getNearbyDonors({ lat, lng, radiusKm = 50 }) {
  const res = await api.get('/donors/', {
    params: {
      lat,
      lng,
      radius_km: radiusKm,
      is_available: true,
    },
  })
  return res.data
}