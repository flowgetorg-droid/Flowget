import { supabase } from './supabase';

const SESSION_KEY = 'flowget_visitor_session_v1';
const getSessionId = () => {
  try {
    let id = localStorage.getItem(SESSION_KEY);
    if (!id) {
      id = (crypto?.randomUUID?.() || `${Date.now()}-${Math.random().toString(36).slice(2)}`);
      localStorage.setItem(SESSION_KEY, id);
    }
    return id;
  } catch {
    return `${Date.now()}-${Math.random().toString(36).slice(2)}`;
  }
};

const deviceType = () => {
  const w = window.innerWidth;
  return w < 768 ? 'mobile' : w < 1024 ? 'tablet' : 'desktop';
};

export async function trackVisitor(path) {
  if (!supabase || typeof window === 'undefined') return;
  const session_id = getSessionId();
  try {
    await supabase.rpc('track_visitor_session', {
      p_session_id: session_id,
      p_path: path || '/',
      p_device_type: deviceType(),
      p_referrer: document.referrer || null
    });
    await supabase.from('analytics_events').insert({
      event_name: 'page_view',
      path: path || '/',
      session_id,
      metadata: { device_type: deviceType() }
    });
  } catch (e) {
    // Analytics must never block or refresh the customer app.
    console.warn('FlowGet analytics:', e?.message || e);
  }
}

export function startVisitorTracking(path) {
  if (!supabase || typeof window === 'undefined') return () => {};
  let stopped = false;
  const send = () => { if (!stopped) trackVisitor(path); };
  send();
  const interval = window.setInterval(send, 5 * 60 * 1000);
  return () => { stopped = true; window.clearInterval(interval); };
}
