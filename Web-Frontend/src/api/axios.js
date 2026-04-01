import axios from 'axios'
import { firebaseAuth } from './auth'

function getApiBaseUrl() {
  const url = import.meta.env.VITE_API_URL
  return url || 'http://localhost:5174'
}

export const api = axios.create({
  baseURL: getApiBaseUrl(),
})

api.interceptors.request.use(async (config) => {
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

    if (status === 401) {
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

