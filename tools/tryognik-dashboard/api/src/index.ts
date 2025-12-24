import express from 'express'
import cors from 'cors'
import uploadRouter from './routes/upload'
import metricsRouter from './routes/metrics'
import exportRouter from './routes/export'
import auditRouter from './routes/audit'

const app = express()
app.use(cors())
app.use(express.json())

app.use('/api/v1/upload', uploadRouter)
app.use('/api/v1/metrics', metricsRouter)
app.use('/api/v1/export', exportRouter)
app.use('/api/v1/audit', auditRouter)

app.listen(4000, ()=> console.log('API listening on http://localhost:4000'))
