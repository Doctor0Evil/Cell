import React, { createContext, useContext, useState } from 'react'

export type Role = 'investor' | 'cfo' | 'producer' | 'legal' | 'admin'

type AuthState = {
  role: Role
  setRole: (r: Role) => void
}

const AuthContext = createContext<AuthState | null>(null)

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [role, setRole] = useState<Role>('investor')
  return <AuthContext.Provider value={{ role, setRole }}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}

export function RequireRole({ children, allowed }: { children: React.ReactNode; allowed: Role[] }) {
  const { role } = useAuth()
  if (!allowed.includes(role)) return <div style={{padding:20}}>Access denied for role: {role}</div>
  return <>{children}</>
}
