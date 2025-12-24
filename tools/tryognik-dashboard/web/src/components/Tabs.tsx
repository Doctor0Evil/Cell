import React from 'react'

export default function Tabs(){
  return (
    <div className="tabs">
      <div style={{display:'flex',gap:12}}>
        <button className="small-btn">Finance</button>
        <button className="small-btn">Creative</button>
        <button className="small-btn">Risk</button>
      </div>
      <div style={{marginTop:12}}>
        <div style={{padding:12,color:'#cbd5e1'}}>Tab contents placeholder — click a tab to switch views (MVP)</div>
      </div>
    </div>
  )
}
