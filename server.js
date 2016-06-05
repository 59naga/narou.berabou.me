import express from 'express';
import cors from 'cors';
import compression from 'compression';
import createNarouMiddleware from 'narou-middleware';

const port = process.env.PORT || 59798;

const app = express();
app.set('json spaces', 2);
app.use(cors());
app.use(compression());
app.use(createNarouMiddleware({ r18: true }));
app.listen(port, () => {
  console.log(`listen on ${port}`);
});
