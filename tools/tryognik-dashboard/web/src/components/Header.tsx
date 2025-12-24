import React from 'react'
import { useAuth } from '../context/AuthContext'

export default function Header(){
  const { role, setRole } = useAuth()
  return (
    <div className="header">
      <div style={{display:'flex',gap:12,alignItems:'center'}}>
        <h3 style={{margin:0}}>Tryognik — Production Dashboard</h3>
        <span className="role-pill">{role.toUpperCase()}</span>
      </div>
      <div style={{display:'flex',gap:10,alignItems:'center'}}>
        <select value={role} onChange={e=>setRole(e.target.value as any)} style={{padding:8,borderRadius:6}}>
          <option value="investor">Investor</option>
          <option value="cfo">CFO</option>
          <option value="producer">Producer</option>
          <option value="legal">Legal</option>
          <option value="admin">Admin</option>
        </select>
        <button className="small-btn">Request Briefing</button>
        <button className="small-btn" onClick={async ()=>{
          try{
            const res = await fetch('/api/v1/export/investor-report', { headers: {'x-user-role': role} })
            if (!res.ok) throw new Error('Export failed')
            const blob = await res.blob()
            const url = window.URL.createObjectURL(blob)
            const a = document.createElement('a')
            a.href = url
            a.download = 'tryognik-investor-report.pdf'
            document.body.appendChild(a)
            a.click()
            a.remove()
            window.URL.revokeObjectURL(url)
          }catch(e){
            alert('Export failed: '+ (e as any).message)
          }
        }}>{role==='investor' ? 'Export PDF (Investor)' : 'Export PDF'}</button>
      </div>
    </div>
  )
}
