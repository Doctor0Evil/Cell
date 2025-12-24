import express from 'express'
const router = express.Router()

router.get('/', (req, res) => {
  const globalAny: any = global as any
  const log = globalAny.__TRYOGNIK_AUDIT_LOG__ || []
  return res.json({ log })
})

export default router
