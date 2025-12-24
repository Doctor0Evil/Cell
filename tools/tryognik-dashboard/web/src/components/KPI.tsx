import React from 'react'

export default function KPI({title,value,meta}:{title:string,value:string|number,meta?:string}){
  return (
    <div className="kpi-card">
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}>
        <div>
          <div style={{fontSize:12,color:'#94a3b8'}}>{title}</div>
          <div style={{fontSize:20,fontWeight:700}}>{value}</div>
        </div>
        <div style={{fontSize:12,color:'#94a3b8'}}>{meta}</div>
      </div>
    </div>
  )
}
