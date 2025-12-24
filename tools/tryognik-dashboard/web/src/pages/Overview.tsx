import React, { useState } from 'react'
import Header from '../components/Header'
import LeftNav from '../components/LeftNav'
import KPI from '../components/KPI'
import GanttPlaceholder from '../components/GanttPlaceholder'
import Tabs from '../components/Tabs'
import AuditLog from '../components/AuditLog'
import { useQueryClient, useMutation, useQuery } from '@tanstack/react-query'
import { uploadBudget, fetchOverview } from '../services/api'
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts'
import { useAuth } from '../context/AuthContext'

export default function Overview(){
  const qc = useQueryClient()
  const { data } = useQuery(['overview'], fetchOverview)
  const m = useMutation(uploadBudget, { onSuccess: () => qc.invalidateQueries(['overview']) })
  const [file, setFile] = useState<File | null>(null)
  const { role } = useAuth()

  return (
    <div style={{display:'flex',width:'100%'}}>
      <LeftNav />
      <div className="main">
        <Header />
        <div style={{marginTop:16}} className="kpi-row">
          <KPI title="Burn Rate (daily)" value={data?.burnRateDaily ? `$${data.burnRateDaily.toFixed(0)}` : '—'} meta="Last 30d" />
          <KPI title="Cash On Hand" value={data?.cashOnHand ? `$${data.cashOnHand.toFixed(0)}` : '—'} />
          <KPI title="Cash Runway" value={data?.cashRunwayDays ? `${Math.round(data.cashRunwayDays)} days` : '—'} />
          <KPI title="Schedule Health" value="On Track" />
          <KPI title="Risk Index" value="Low" />
        </div>

        <div style={{display:'grid',gridTemplateColumns:'1fr 360px',gap:16}}>
          <GanttPlaceholder />
          <div style={{background:'#0b1220',borderRadius:8,padding:12}}>
            <h4 style={{marginTop:0}}>Milestone Detail</h4>
            <div style={{color:'#94a3b8'}}>Select a milestone to view details — placeholder</div>
            <div className="upload">
              <input type="file" accept="text/csv" onChange={e=>setFile(e.target.files?.[0]??null)} />
              <button className="small-btn" onClick={() => file && m.mutate(file)} style={{marginLeft:8}} disabled={role==='investor'}>{role==='investor' ? 'Upload (read-only)' : 'Upload CSV'}</button>
              <button className="small-btn" style={{marginLeft:8}} onClick={() => fetch('/api/v1/upload/load-sample').then(()=>qc.invalidateQueries(['overview']))}>Load Sample</button>
            </div>
          </div>
        </div>

        <div style={{marginTop:16}}>
          <Tabs />
          <div style={{marginTop:12}}>
            <h4 style={{marginBottom:8}}>12 Month Cashflow</h4>
            <div style={{height:220}}>
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={data?.monthly ?? []}>
                  <XAxis dataKey="month" stroke="#94a3b8" />
                  <YAxis stroke="#94a3b8" />
                  <Tooltip />
                  <Line type="monotone" dataKey="cash" stroke="#c0422a" strokeWidth={2} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>

        <AuditLog />
      </div>
    </div>
  )
}
