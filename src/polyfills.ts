/**
 * This file includes polyfills needed by Angular and is loaded before the app.
 * You can add your own extra polyfills to this file.
 */

/** Zone JS is required by default for Angular itself. */
import 'zone.js';  // Included with Angular CLI.

/** Polyfill for `global` to fix @stomp/stompjs in browser */
if (typeof window !== 'undefined') {
  (window as any).global = window;
  console.log('Polyfill applied: global is defined');
}