// Structured logging for edge functions — one JSON line per event.
// PII RULE: ids / codes / counts / booleans only.

type Level = 'info' | 'warn' | 'error';

export function log(
  level: Level,
  fn: string,
  event: string,
  fields: Record<string, unknown> = {},
): void {
  const line = JSON.stringify({
    level,
    fn,
    event,
    at: new Date().toISOString(),
    ...fields,
  });
  if (level === 'error') console.error(line);
  else if (level === 'warn') console.warn(line);
  else console.log(line);
}

export const logInfo = (fn: string, event: string, fields?: Record<string, unknown>): void =>
  log('info', fn, event, fields);
export const logWarn = (fn: string, event: string, fields?: Record<string, unknown>): void =>
  log('warn', fn, event, fields);
export const logError = (fn: string, event: string, fields?: Record<string, unknown>): void =>
  log('error', fn, event, fields);

