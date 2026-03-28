const http = require('node:http');
const host = process.env.HOST || '0.0.0.0';
const port = Number(process.env.PORT || 8082);

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end('{"status":"ok"}');
    return;
  }

  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end('{"error":"not found"}');
});

server.listen(port, host, () => {
  console.log(`Node server em ${host}:${port}`);
});
