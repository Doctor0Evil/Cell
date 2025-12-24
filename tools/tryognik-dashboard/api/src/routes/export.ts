import express from 'express'
import PDFDocument from 'pdfkit'

const router = express.Router()

router.get('/investor-report', (req, res) => {
  const role = (req.headers['x-user-role'] as string) || 'anonymous'
  // In production, enforce auth & RBAC properly
  const globalAny: any = global as any
  const m = globalAny.__TRYOGNIK_METRICS__ || {}
  // Audit log
  globalAny.__TRYOGNIK_AUDIT_LOG__ = globalAny.__TRYOGNIK_AUDIT_LOG__ || []
  globalAny.__TRYOGNIK_AUDIT_LOG__.unshift({ time: new Date().toISOString(), action: 'export_report', role, ip: req.ip })

  res.setHeader('Content-Type', 'application/pdf')
  res.setHeader('Content-Disposition', 'attachment; filename="tryognik-investor-report.pdf"')

  const doc = new PDFDocument({ margin: 40 })
  doc.pipe(res)

  doc.fontSize(18).text('Tryognik — Investor Report', { align: 'center' })
  doc.moveDown(0.5)
  doc.fontSize(10).text(`Generated: ${new Date().toISOString()}`)
  doc.moveDown()

  doc.fontSize(12).text('Overview', { underline: true })
  doc.moveDown(0.2)
  doc.text(`Burn Rate (daily): ${m.burnRateDaily ? '$' + m.burnRateDaily.toFixed(2) : 'N/A'}`)
  doc.text(`Cash On Hand: ${m.cashOnHand ? '$' + m.cashOnHand.toFixed(2) : 'N/A'}`)
  doc.text(`Cash Runway (days): ${m.cashRunwayDays ? Math.round(m.cashRunwayDays) : 'N/A'}`)
  doc.moveDown()

  doc.text('Department Budget vs Actual', { underline: true })
  doc.moveDown(0.2)
  const dept: any[] = m.dept || []
  if (dept.length === 0) {
    doc.text('No departmental data available')
  } else {
    dept.forEach(d => {
      doc.text(`${d.department}: actual $${d.actual.toFixed(2)} vs budget $${d.budget.toFixed(2)} (variance ${d.variancePct.toFixed(1)}%)`)
    })
  }

  doc.moveDown()
  doc.text('Notes', { underline: true })
  doc.moveDown(0.2)
  doc.text('This report was generated from Tryognik Dashboard MVP metrics. For legal and financial advice, consult your auditors.')

  doc.end()
})

export default router
