import { BrowserRouter, Navigate, Route, Routes, useLocation } from 'react-router-dom'
import { useAuth } from '../context/AuthContext.jsx'
import { USE_MOCK } from '../config.js'
import LoadingSpinner from '../components/LoadingSpinner.jsx'
import ToastHost from '../components/ToastHost.jsx'

import Login from '../pages/Login.jsx'
import Register from '../pages/register.jsx'

import HospitalDashboard from '../pages/hospital/Dashboard.jsx'
import HospitalMyRequests from '../pages/hospital/MyRequests.jsx'
import HospitalCreateRequest from '../pages/hospital/CreateRequest.jsx'
import HospitalProfile from '../pages/hospital/Profile.jsx'

import AdminDashboard from '../pages/admin/Dashboard.jsx'
import AdminAllRequests from '../pages/admin/AllRequests.jsx'
import AdminHospitals from '../pages/admin/Hospitals.jsx'
import AdminDonors from '../pages/admin/Donors.jsx'


function AuthGate({ children }) {
  const { user, loading } = useAuth()
  const location = useLocation()

  if (USE_MOCK) return children

  if (loading) return <LoadingSpinner />
  if (!user) return <Navigate to="/login" replace state={{ from: location.pathname }} />
  return children
}

function RoleGate({ allow, children, fallbackTo }) {
  const { role, loading } = useAuth()
  if (USE_MOCK) return children

  if (loading) return <LoadingSpinner />
  if (!allow.includes(role)) return <Navigate to={fallbackTo} replace />
  return children
}

function RoleHomeRedirect() {
  const { role, loading } = useAuth()
  if (USE_MOCK) return <Navigate to="/login" replace />

  if (loading) return <LoadingSpinner />
  if (role === 'admin') return <Navigate to="/admin/dashboard" replace />
  if (role === 'hospital') return <Navigate to="/hospital/dashboard" replace />
  return <Navigate to="/login" replace />
}

export default function AppRouter() {
  return (
    <BrowserRouter>
      <ToastHost />
      <Routes>
        <Route path="/" element={<RoleHomeRedirect />} />
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />


        <Route
          path="/hospital/dashboard"
          element={
            <AuthGate>
              <RoleGate allow={['hospital']} fallbackTo="/admin/dashboard">
                <HospitalDashboard />
              </RoleGate>
            </AuthGate>
          }
        />
        <Route
          path="/hospital/my-requests"
          element={
            <AuthGate>
              <RoleGate allow={['hospital']} fallbackTo="/admin/dashboard">
                <HospitalMyRequests />
              </RoleGate>
            </AuthGate>
          }
        />
        <Route
          path="/hospital/create-request"
          element={
            <AuthGate>
              <RoleGate allow={['hospital']} fallbackTo="/admin/dashboard">
                <HospitalCreateRequest />
              </RoleGate>
            </AuthGate>
          }
        />
        <Route
          path="/hospital/profile"
          element={
            <AuthGate>
              <RoleGate allow={['hospital']} fallbackTo="/admin/dashboard">
                <HospitalProfile />
              </RoleGate>
            </AuthGate>
          }
        />

        <Route
          path="/admin/dashboard"
          element={
            <AuthGate>
              <RoleGate allow={['admin']} fallbackTo="/hospital/dashboard">
                <AdminDashboard />
              </RoleGate>
            </AuthGate>
          }
        />
        <Route
          path="/admin/all-requests"
          element={
            <AuthGate>
              <RoleGate allow={['admin']} fallbackTo="/hospital/dashboard">
                <AdminAllRequests />
              </RoleGate>
            </AuthGate>
          }
        />
        <Route
          path="/admin/hospitals"
          element={
            <AuthGate>
              <RoleGate allow={['admin']} fallbackTo="/hospital/dashboard">
                <AdminHospitals />
              </RoleGate>
            </AuthGate>
          }
        />
        <Route
          path="/admin/donors"
          element={
            <AuthGate>
              <RoleGate allow={['admin']} fallbackTo="/hospital/dashboard">
                <AdminDonors />
              </RoleGate>
            </AuthGate>
          }
        />

        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  )
}

