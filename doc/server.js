const express = require('express')
const app = express()
app.use(express.static('./build/site'))
app.get('/', (req, res) => res.redirect('/neo4j-helm/1.0.0'))
app.listen(8000, () => console.log('📘 http://localhost:8000'))


