import React from 'react'

import React from 'react'
import useSWR from 'swr'

const fetcher = (url:string) => fetch(url).then(r=>r.json())

export default function AuditLog(){
  const { data } = useSWR('/api/v1/audit', fetcher, { refreshInterval: 5000 })
  const log = data?.log ?? []
  return (
    <div className="audit-log">
      <h4 style={{marginTop:0}}>Activity Feed</h4>
      <ul>
        {log.length === 0 ? <li style={{color:'#94a3b8',padding:6}}>No events yet</li> : log.map((s:any,i:number)=> <li key={i} style={{color:'#94a3b8',padding:6}}>{s.time} — {s.action} — {s.role || 'system'}</li>)}
      </ul>
    </div>
  )
}
