import axios from 'axios'

const API = axios.create({ baseURL: '/api/v1' })

export async function uploadBudget(file: File){
  const fd = new FormData()
  fd.append('file', file)
  const res = await API.post('/upload/budget', fd, { headers: {'Content-Type':'multipart/form-data'} })
  return res.data
}

export async function fetchOverview(){
  const res = await API.get('/metrics/overview')
  return res.data
}

export async function loadSample(){
  const res = await API.get('/upload/load-sample')
  return res.data
}
