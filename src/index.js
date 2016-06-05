import React from 'react';
import ReactDOM from 'react-dom';

import store from './store';
import createSyncHistory from './history';

import { Provider } from 'react-redux';
import { Router } from 'react-router';
import routes from './routes';

import 'velocity-animate';
import 'velocity-animate/velocity.ui';
import './index.styl';

const history = createSyncHistory(store);

window.addEventListener('DOMContentLoaded', () => {
  ReactDOM.render((
    <Provider store={store}>
      <Router history={history} routes={routes} />
    </Provider>
  ), document.querySelector('#main'));
});
