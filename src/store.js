import { createStore, combineReducers } from 'redux';
import { routerReducer as routing } from 'react-router-redux';

export default createStore(combineReducers({ routing }));
