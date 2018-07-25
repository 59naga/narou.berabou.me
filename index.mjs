import express from 'express';
import compression from 'compression';
import narouMiddleware from 'narou-middleware';
import bluebird from 'bluebird';
import request from 'request';

const port = process.env.PORT || 8080;
const requestAsync = bluebird.promisify(request, { multiArgs: true });

const scraped = (res, { statusCode, body }) => {
  res.status(statusCode);
  res.set('Content-type', 'text/html');
  return res.end(body);
};

const app = express();
app.use(compression());
app.use('/scrape/', async (req, res, next) => {
  const url = req.url.slice(1);
  if (url.length === 0) {
    return next();
  }

  try {
    const [response] = await requestAsync(url);
    const { statusCode, body } = response;
    res.status(statusCode);
    res.set('Content-type', 'text/html');
    res.end(body);
  } catch (error) {
    res.status(500).end(error.stack);
  }
});
app.use(narouMiddleware({ r18: true }));

app.listen(port, () => {
  console.log('Server running at http://localhost:%s', port);
});
