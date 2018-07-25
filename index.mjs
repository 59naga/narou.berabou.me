import express from 'express';
import compression from 'compression';
import narouMiddleware from 'narou-middleware';
import request from 'request';

const port = process.env.PORT || 8080;
const waybackAPI = 'http://archive.org/wayback/available?url=';

const app = express();
app.use(compression());
app.use('/scrape/', (req, res, next) => {
  const url = req.url.slice(1);
  if (url.length === 0) {
    return next();
  }

  res.status(200);
  res.set('Content-type', 'text/html');
  request(url).pipe(res);
});
app.use(narouMiddleware({ r18: true }));

app.listen(port, () => {
  console.log('Server running at http://localhost:%s', port);
});
