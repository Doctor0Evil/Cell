import express from 'express'
const router = express.Router()

// pulled from upload route's in-memory store
let lastMetrics: any = null

// sync with upload route by reading module cache
try{
  const uploadModule = require('./upload')
  // not ideal but fine for MVP
} catch(e){ }

router.get('/overview', (req, res) => {
  // For MVP, allow metrics to be stored on global (process) - in real app use DB or cache
  const globalAny: any = global as any
  const m = globalAny.__TRYOGNIK_METRICS__
  if (m) return res.json(m)
  return res.json({burnRateDaily:0,burnRateMonthly:0,cashOnHand:0,cashRunwayDays:null,dept:[],monthly:[]})
})

export default router
