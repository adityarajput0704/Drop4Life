import axios from 'axios'
import { firebaseAuth } from './auth'
import { USE_MOCK } from '../config.js'

function getApiBaseUrl() {
  const url = import.meta.env.VITE_API_URL
  return url || 'http://192.168.0.107:8000'
}

export const api = axios.create({
  baseURL: getApiBaseUrl(),
})

const MOCK_DATA = {
  '/users/me': { role: 'admin', name: 'Mock User', email: 'mock@test.com' },
  '/blood-requests/admin/all': {
    items: [
      { id: '1', request_id: 'REQ-MOCK1', hospital: 'City Care Hospital', blood_group: 'O+', units: 2, patient: 'Suresh Patil', urgency: 'CRITICAL', status: 'OPEN', created_at: new Date().toISOString() },
      { id: '2', request_id: 'REQ-MOCK2', hospital: 'Metro General', blood_group: 'A-', units: 1, patient: 'Ramesh Kumar', urgency: 'URGENT', status: 'FULFILLED', created_at: new Date().toISOString() },
    ],
    total: 2
  },
  '/blood-requests/my-requests': {
    items: [
      { id: '3', request_id: 'REQ-MOCK3', blood_group: 'B+', units: 3, patient: 'Rahul S.', urgency: 'NORMAL', status: 'OPEN', created_at: new Date().toISOString() }
    ],
    total: 1
  },
  '/blood-requests': {
    items: [
      { id: '4', request_id: 'REQ-MOCK4', hospital: 'Mock Hospital', blood_group: 'O+', units: 2, patient: 'John Doe', urgency: 'CRITICAL', status: 'OPEN', created_at: new Date().toISOString() }
    ],
    total: 1
  },
  '/donors/': {
    items: [], total: 100
  },
  '/hospitals/': {
    items: [], total: 25
  }
}

api.interceptors.request.use(async (config) => {
  if (USE_MOCK) {
    config.adapter = async (configParams) => {
      let data = { items: [], total: 0 }
      const url = configParams.url || ''
      for (const [key, val] of Object.entries(MOCK_DATA)) {
        if (url.includes(key)) {
          data = val
          break
        }
      }
      return {
        data,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: configParams,
        request: {}
      }
    }
    return config
  }

  const user = firebaseAuth?.currentUser
  if (!user) return config

  const token = await user.getIdToken()
  config.headers = config.headers || {}
  config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  (res) => res,
  (error) => {
    const status = error?.response?.status

    // Only redirect on 401 if NOT an auth-resolution call
    // Auth context handles /hospitals/me and /users/me failures itself
    const url = error?.config?.url || ''
    const isAuthResolution = url.includes('/hospitals/me') || url.includes('/users/me')

    if (status === 401 && !isAuthResolution) {
      window.location.href = '/login'
    }

    if (status === 429) {
      window.dispatchEvent(
        new CustomEvent('app:toast', {
          detail: { type: 'error', message: 'Too many requests, please slow down' },
        }),
      )
    }

    return Promise.reject(error)
  },
)

