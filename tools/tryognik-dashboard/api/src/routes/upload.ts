import express from 'express'
import multer from 'multer'
import fs from 'fs'
import path from 'path'
import { parse } from 'csv-parse'

const router = express.Router()
const upload = multer({ dest: path.join(__dirname,'../../tmp') })

// In-memory metrics store for MVP
let lastMetrics: any = null

router.post('/budget', upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).json({error:'file required'})
  const filePath = req.file.path
  const raw = fs.readFileSync(filePath)

  parse(raw, { columns: true, trim: true }, (err, records: any[]) => {
    if (err) return res.status(400).json({error:err.message})

    // Expect columns: date, vendor, department, line_item, amount, type(actual|budget), currency
    const now = new Date()
    const thirtyDaysAgo = new Date(now.getTime() - 30*24*60*60*1000)

    let totalActual30 = 0
    const dept: Record<string, {budget:number, actual:number}> = {}
    let cashOnHand = 0

    for(const r of records){
      const amt = parseFloat(r.amount || '0')
      const type = (r.type||'actual').toLowerCase()
      const date = r.date ? new Date(r.date) : null
      const department = r.department || 'Unknown'

      if (!dept[department]) dept[department] = {budget:0, actual:0}
      if (type === 'budget') dept[department].budget += amt
      else dept[department].actual += amt

      if (type !== 'budget' && date && date >= thirtyDaysAgo) totalActual30 += amt

      // special line item to indicate starting cash
      if ((r.line_item||'').toLowerCase() === 'starting_cash'){
        cashOnHand = amt
      }
    }

    const burnRateDaily = totalActual30 / 30
    const burnRateMonthly = burnRateDaily * 30
    const cashRunwayDays = burnRateDaily>0 ? cashOnHand / burnRateDaily : null

    const deptArr = Object.keys(dept).map(k=>({department:k,budget:dept[k].budget,actual:dept[k].actual,variancePct: dept[k].budget>0 ? ((dept[k].actual-dept[k].budget)/dept[k].budget)*100 : 0}))

    // Build monthly time series (simple)
    const monthly: any[] = []
    for(let i=11;i>=0;i--){
      const dt = new Date(now.getFullYear(), now.getMonth()-i, 1)
      const month = dt.toISOString().slice(0,7)
      const sum = records.filter(r=>r.date && r.date.startsWith(month) && (r.type||'actual').toLowerCase()!=='budget').reduce((s:any,r:any)=>s+parseFloat(r.amount||0),0)
      monthly.push({month, cash: sum})
    }

    lastMetrics = {burnRateDaily,burnRateMonthly,cashOnHand,cashRunwayDays,dept:deptArr,monthly}
    // publish to global for simple MVP retrieval
    ;(global as any).__TRYOGNIK_METRICS__ = lastMetrics
    fs.unlinkSync(filePath)
    return res.json({ok:true, metrics:lastMetrics})
  })
})

// Helper route: load server sample CSV into metrics (demo convenience)
router.get('/load-sample', (req, res) => {
  const samplePath = path.join(__dirname,'../../sample_data/sample_budget.csv')
  const raw = fs.readFileSync(samplePath)
  parse(raw, { columns: true, trim: true }, (err, records: any[]) => {
    if (err) return res.status(400).json({error:err.message})
    // reuse same computation logic
    const now = new Date()
    const thirtyDaysAgo = new Date(now.getTime() - 30*24*60*60*1000)
    let totalActual30 = 0
    const dept: Record<string, {budget:number, actual:number}> = {}
    let cashOnHand = 0
    for(const r of records){
      const amt = parseFloat(r.amount || '0')
      const type = (r.type||'actual').toLowerCase()
      const date = r.date ? new Date(r.date) : null
      const department = r.department || 'Unknown'
      if (!dept[department]) dept[department] = {budget:0, actual:0}
      if (type === 'budget') dept[department].budget += amt
      else dept[department].actual += amt
      if (type !== 'budget' && date && date >= thirtyDaysAgo) totalActual30 += amt
      if ((r.line_item||'').toLowerCase() === 'starting_cash'){
        cashOnHand = amt
      }
    }
    const burnRateDaily = totalActual30 / 30
    const burnRateMonthly = burnRateDaily * 30
    const cashRunwayDays = burnRateDaily>0 ? cashOnHand / burnRateDaily : null
    const deptArr = Object.keys(dept).map(k=>({department:k,budget:dept[k].budget,actual:dept[k].actual,variancePct: dept[k].budget>0 ? ((dept[k].actual-dept[k].budget)/dept[k].budget)*100 : 0}))
    const monthly: any[] = []
    for(let i=11;i>=0;i--){
      const dt = new Date(now.getFullYear(), now.getMonth()-i, 1)
      const month = dt.toISOString().slice(0,7)
      const sum = records.filter(r=>r.date && r.date.startsWith(month) && (r.type||'actual').toLowerCase()!=='budget').reduce((s:any,r:any)=>s+parseFloat(r.amount||0),0)
      monthly.push({month, cash: sum})
    }
    lastMetrics = {burnRateDaily,burnRateMonthly,cashOnHand,cashRunwayDays,dept:deptArr,monthly}
    ;(global as any).__TRYOGNIK_METRICS__ = lastMetrics
    return res.json({ok:true, metrics:lastMetrics})
  })
})

export default router
