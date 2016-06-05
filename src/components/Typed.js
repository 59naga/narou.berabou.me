import React from 'react';
import { VelocityTransitionGroup } from 'velocity-react';
import arrayFrom from 'array-from';

export default (props) => (
  <VelocityTransitionGroup
    runOnMount
    enter={{
      animation: 'transition.shrinkIn',
      stagger: 100,
    }}
  >
    {arrayFrom(props.children).map((gryph, i) => <span key={i}>{gryph}</span>)}
  </VelocityTransitionGroup>
);
