const http = require('http');
const fs = require('fs');
const path = require('path');
const root = __dirname;

http.createServer((req, res) => {
  if (req.method === 'POST' && req.url.startsWith('/save')) {
    let body = '';
    req.on('data', d => body += d);
    req.on('end', () => {
      try {
        const m = body.match(/^data:image\/(png|jpeg|jpg|webp);base64,(.*)$/s);
        if (!m) { res.writeHead(400); return res.end('bad'); }
        const ext = m[1] === 'jpeg' ? 'jpg' : m[1];
        const dest = path.join(root, 'assets', 'gen');
        fs.mkdirSync(dest, { recursive: true });
        fs.writeFileSync(path.join(dest, 'snapshot.' + ext), Buffer.from(m[2], 'base64'));
        res.writeHead(200, { 'content-type': 'text/plain' });
        res.end('saved ' + (Buffer.byteLength(m[2])) + 'b');
      } catch (e) { res.writeHead(500); res.end(String(e)); }
    });
    return;
  }
  let p = req.url.split('?')[0];
  if (p === '/') p = '/index.html';
  const file = path.join(root, decodeURIComponent(p));
  if (fs.existsSync(file) && fs.statSync(file).isFile()) {
    res.writeHead(200, { 'content-type': p.endsWith('.html') ? 'text/html; charset=utf-8' : 'application/octet-stream', 'cache-control': 'no-store' });
    fs.createReadStream(file).pipe(res);
  } else { res.writeHead(404); res.end('404'); }
}).listen(3311, '127.0.0.1', () => console.log('serving on http://127.0.0.1:3311'));
