import React from 'react'

const items = ['Overview','Finance','Schedule','Creative','Risk','Assets','Documents','Investors','Audit Log','Settings']

export default function LeftNav(){
  return (
    <div className="left-nav">
      <h4 style={{marginTop:0}}>Navigation</h4>
      <ul style={{listStyle:'none',padding:0}}>
        {items.map(i=> <li key={i} style={{padding:'8px 6px',cursor:'pointer',color:'#cbd5e1'}}>{i}</li>)}
      </ul>
    </div>
  )
}
