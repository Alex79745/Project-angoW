const express = require('express');
const mysql = require('mysql2/promise');
const app = express();
const port = process.env.BACKEND_PORT || 3000;

let pool;
async function initDb(){
  try{
    pool = mysql.createPool({
      host: process.env.DB_HOST || 'mysql',
      user: process.env.DB_USER || 'hotel_user',
      password: process.env.DB_PASSWORD || 'change_me',
      database: process.env.DB_NAME || 'hotel_db',
      waitForConnections: true,
      connectionLimit: 10,
    });
    await pool.query('CREATE TABLE IF NOT EXISTS bookings (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100), room INT, created TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    console.log('DB ready');
  }catch(err){ console.error('DB init error', err) }
}

app.get('/health', (req,res)=> res.json({ok:true}));

app.get('/api/bookings', async (req,res)=>{
  try{
    const [rows] = await pool.query('SELECT * FROM bookings ORDER BY id DESC LIMIT 20');
    res.json({count: rows.length, bookings: rows});
  }catch(err){ res.status(500).json({error:err.message}) }
});

app.post('/api/bookings', express.json(), async (req,res)=>{
  const {name, room} = req.body;
  if(!name || !room) return res.status(400).json({error:'name and room required'});
  try{
    const [resu] = await pool.query('INSERT INTO bookings (name, room) VALUES (?,?)',[name,room]);
    res.json({id: resu.insertId});
  }catch(err){ res.status(500).json({error:err.message}) }
});

initDb().then(()=> app.listen(port, ()=> console.log('Backend listening on', port)));
