// Test-only preload: inherited by detached Node workers through NODE_OPTIONS.
import { readFileSync } from 'node:fs';
import { setInterval, clearInterval } from 'node:timers';

const file = process.env.DURABLE_TEST_CLOCK;
if (!file) throw new Error('test-clock requires DURABLE_TEST_CLOCK');
const realNow = Date.now.bind(Date);
Date.now = () => realNow() + JSON.parse(readFileSync(file, 'utf8')).offsetMs;

// Poll real time, but fire against the shared virtual deadline. Return a native
// timer handle so pi-durable can still ref/unref/cancel its timers normally.
globalThis.setTimeout = (callback, delay = 0, ...args) => {
  const deadline = Date.now() + Math.max(0, Number(delay) || 0);
  const timer = setInterval(() => {
    if (Date.now() >= deadline) {
      clearInterval(timer);
      callback(...args);
    }
  }, 10);
  return timer;
};
