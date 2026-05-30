// Three Daily Goals — iOS App UI Components
// Shared components exported to window for use in index.html

const TDG_COLORS = {
  accent:   '#EA580C',           // brand orange — keep full strength, it's intentional
  priority: '#E8900A',           // softer orange (was #FF9500)
  open:     '#3B82C4',           // muted blue (was #007AFF)
  pending:  '#B59A00',           // muted gold (was #CCAA00)
  closed:   '#4A9E6A',           // muted green (was #34C759)
  dead:     '#8C7058',           // muted brown (was #A2845E)
  dueSoon:  '#D94F47',           // softer red (was #FF3B30)
  neutral50:  '#FAFAFA',
  neutral100: '#F5F5F5',
  neutral200: '#E8E8E8',         // slightly warmer
  neutral300: '#D8D8D8',
  neutral500: '#9A9A9A',
  neutral700: '#5E5E5E',
  neutral800: '#404040',
  eemDeepWork:       '#B4A5D5',  // unchanged — already muted
  eemSteadyProgress: '#7BB8BA',
  eemSprintTasks:    '#F4A89A',
  eemEasyWins:       '#A8D5BA',
};

const compStyles = {
  phone: {
    width: 393, height: 852,
    background: '#F2F2F7',
    borderRadius: 44,
    overflow: 'hidden',
    position: 'relative',
    fontFamily: 'ui-sans-serif, system-ui, -apple-system, sans-serif',
    boxShadow: '0 30px 80px rgba(0,0,0,0.35), 0 0 0 1px rgba(0,0,0,0.15)',
    display: 'flex', flexDirection: 'column',
    flexShrink: 0,
  }
};

// ── Status Bar ──────────────────────────────────────────────────────────────
function StatusBar({ dark = false }) {
  const color = dark ? '#fff' : '#000';
  return (
    <div style={{
      height: 54, display: 'flex', alignItems: 'flex-end',
      justifyContent: 'space-between', padding: '0 24px 8px',
      background: 'transparent', flexShrink: 0,
    }}>
      <span style={{ fontSize: 15, fontWeight: 700, color }}>9:41</span>
      <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
        <span style={{ fontSize: 13, color }}>●●●</span>
        <span style={{ fontSize: 13, color }}>WiFi</span>
        <span style={{ fontSize: 13, color }}>⬛</span>
      </div>
    </div>
  );
}

// ── Navigation Bar ──────────────────────────────────────────────────────────
function NavBar({ title, leftItems, rightItems, tintColor = TDG_COLORS.open, bg = '#F2F2F7' }) {
  return (
    <div style={{
      height: 44, background: bg,
      borderBottom: `1px solid ${TDG_COLORS.neutral200}`,
      display: 'flex', alignItems: 'center',
      justifyContent: 'space-between', padding: '0 14px',
      flexShrink: 0,
    }}>
      <div style={{ display: 'flex', gap: 10, minWidth: 60 }}>{leftItems}</div>
      <span style={{ fontSize: 17, fontWeight: 600, color: '#000', flex: 1, textAlign: 'center' }}>{title}</span>
      <div style={{ display: 'flex', gap: 12, minWidth: 60, justifyContent: 'flex-end', alignItems: 'center' }}>{rightItems}</div>
    </div>
  );
}

// ── EEM Quadrant Indicator ──────────────────────────────────────────────────
function EEMIndicator({ quadrant }) {
  // quadrant: 'deepWork' | 'sprint' | 'steady' | 'easyWin' | null
  const colors = {
    deepWork:    [TDG_COLORS.eemDeepWork,    'rgba(0,0,0,0.1)', 'rgba(0,0,0,0.1)', 'rgba(0,0,0,0.1)'],
    sprint:      ['rgba(0,0,0,0.1)', TDG_COLORS.eemSprintTasks, 'rgba(0,0,0,0.1)', 'rgba(0,0,0,0.1)'],
    steady:      ['rgba(0,0,0,0.1)', 'rgba(0,0,0,0.1)', TDG_COLORS.eemSteadyProgress, 'rgba(0,0,0,0.1)'],
    easyWin:     ['rgba(0,0,0,0.1)', 'rgba(0,0,0,0.1)', 'rgba(0,0,0,0.1)', TDG_COLORS.eemEasyWins],
  };
  const quads = quadrant ? colors[quadrant] : ['rgba(0,0,0,0.08)', 'rgba(0,0,0,0.08)', 'rgba(0,0,0,0.08)', 'rgba(0,0,0,0.08)'];
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gridTemplateRows: '1fr 1fr', gap: 1, width: 18, height: 18, flexShrink: 0, opacity: quadrant ? 0.85 : 0.3 }}>
      {quads.map((c, i) => <div key={i} style={{ background: c, borderRadius: 1 }}></div>)}
    </div>
  );
}

// ── Task Row ────────────────────────────────────────────────────────────────
function TaskRow({ title, quadrant = null, due = null, dueUrgent = false, onTap }) {
  return (
    <div onClick={onTap} style={{
      display: 'flex', alignItems: 'center', gap: 8,
      background: '#fff',
      border: `1px solid ${TDG_COLORS.neutral200}`,
      borderRadius: 8, padding: '9px 10px',
      boxShadow: 'rgba(0,0,0,0.04) 0px 1px 3px',
      cursor: 'pointer', userSelect: 'none',
    }}>
      <EEMIndicator quadrant={quadrant} />
      <span style={{ flex: 1, fontSize: 14, color: '#111', lineHeight: 1.4 }}>{title}</span>
      {due && <span style={{ fontSize: 11, color: dueUrgent ? TDG_COLORS.dueSoon : TDG_COLORS.neutral500, fontStyle: 'italic', flexShrink: 0 }}>{due}</span>}
    </div>
  );
}

// ── List Container ──────────────────────────────────────────────────────────
function ListContainer({ state, children, count }) {
  const stateConfig = {
    priority: { color: TDG_COLORS.priority, icon: '★', label: 'Today\'s Goals' },
    open:     { color: TDG_COLORS.open,     icon: '○', label: 'Open'          },
    pending:  { color: TDG_COLORS.pending,  icon: '◷', label: 'Pending'       },
    closed:   { color: TDG_COLORS.closed,   icon: '●', label: 'Closed'        },
    dead:     { color: TDG_COLORS.dead,     icon: '▦', label: 'Graveyard'     },
  };
  const cfg = stateConfig[state] || stateConfig.open;
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
      {/* Header row matching real app: colored circle icon + label + count badge */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '2px 4px' }}>
        <span style={{ color: cfg.color, fontSize: 16 }}>{cfg.icon}</span>
        <span style={{ fontSize: 16, fontWeight: 700, color: '#111' }}>{cfg.label}</span>
        {count != null && (
          <span style={{
            fontSize: 12, fontWeight: 600, color: cfg.color,
            background: `${cfg.color}18`,
            padding: '1px 7px', borderRadius: 10,
          }}>{count}</span>
        )}
      </div>
      {/* Optional section sub-header */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
        {children}
      </div>
    </div>
  );
}

// ── Streak Widget ───────────────────────────────────────────────────────────
function StreakWidget({ streak = 42, done = true, onCompassCheck }) {
  return (
    <div style={{
      background: '#fff',
      border: `1px solid ${TDG_COLORS.neutral200}`,
      borderRadius: 10, padding: '10px 14px',
      boxShadow: 'rgba(0,0,0,0.04) 0px 1px 3px',
      display: 'flex', flexDirection: 'column', gap: 8,
    }}>
      {/* "42 🔥 Today: ✓" row */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 14 }}>
        <span style={{ fontWeight: 700, fontSize: 15 }}>{streak}</span>
        <span style={{ fontSize: 15 }}>🔥</span>
        <span style={{ fontWeight: 500, color: '#333', fontSize: 13 }}>Today:</span>
        <span style={{ fontSize: 16, color: done ? TDG_COLORS.closed : TDG_COLORS.open, fontWeight: 700 }}>
          {done ? '✓' : '○'}
        </span>
      </div>
      <button onClick={onCompassCheck} style={{
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        gap: 6, padding: '8px 14px',
        background: TDG_COLORS.accent, color: '#fff',
        border: 'none', borderRadius: 20,
        fontSize: 13, fontWeight: 600, cursor: 'pointer',
        width: '100%',
      }}>
        ◎ Start Compass Check Now
      </button>
    </div>
  );
}

// ── Sidebar List Links ──────────────────────────────────────────────────────
function SidebarLinks({ active, onSelect }) {
  const lists = [
    { key: 'open',    icon: '○', label: 'Open',      color: TDG_COLORS.open,    count: 29 },
    { key: 'pending', icon: '◷', label: 'Pending Response', color: TDG_COLORS.pending, count: 1 },
    { key: 'closed',  icon: '●', label: 'Closed',    color: TDG_COLORS.closed,  count: null },
    { key: 'dead',    icon: '▦', label: 'Graveyard', color: TDG_COLORS.dead,    count: null },
  ];
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
      {lists.map(l => (
        <div key={l.key} onClick={() => onSelect && onSelect(l.key)} style={{
          display: 'flex', alignItems: 'center', gap: 10,
          padding: '10px 12px', borderRadius: 10, cursor: 'pointer',
          background: active === l.key ? '#fff' : '#fff',
          border: active === l.key ? `1.5px solid ${l.color}` : `1px solid ${TDG_COLORS.neutral200}`,
          boxShadow: active === l.key ? `rgba(0,0,0,0.06) 0px 1px 4px` : 'none',
          transition: 'border 0.15s, box-shadow 0.15s',
        }}>
          {/* Colored left accent stripe */}
          <div style={{
            width: 3, height: 28, borderRadius: 2,
            background: l.color, flexShrink: 0, alignSelf: 'center',
          }}></div>
          <span style={{ flex: 1, fontSize: 15, fontWeight: active === l.key ? 600 : 400, color: active === l.key ? l.color : '#111' }}>{l.label}</span>
          {l.count != null && (
            <span style={{
              fontSize: 12, fontWeight: 600,
              color: active === l.key ? '#fff' : l.color,
              background: active === l.key ? l.color : `${l.color}22`,
              padding: '2px 8px', borderRadius: 10, minWidth: 24, textAlign: 'center',
            }}>{l.count}</span>
          )}
        </div>
      ))}
    </div>
  );
}

// ── Tag Chips ───────────────────────────────────────────────────────────────
function TagChip({ label, active, color = TDG_COLORS.open, onToggle }) {
  return (
    <button onClick={onToggle} style={{
      padding: '3px 10px', borderRadius: 20,
      border: `1px solid ${active ? color : TDG_COLORS.neutral300}`,
      background: active ? `${color}18` : TDG_COLORS.neutral100,
      color: active ? color : '#555',
      fontSize: 12, fontWeight: active ? 600 : 400,
      cursor: 'pointer',
    }}>{label}</button>
  );
}

// ── Compass Check Dialog ────────────────────────────────────────────────────
function CompassCheckDialog({ step, totalSteps, stepTitle, stepContent, onBack, onNext, onCancel, nextLabel = 'Next' }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, background: '#fff', zIndex: 100,
      display: 'flex', flexDirection: 'column',
    }}>
      {/* Header */}
      <div style={{
        padding: '16px 12px 8px', borderBottom: `1px solid ${TDG_COLORS.neutral200}`,
        display: 'flex', flexDirection: 'column', gap: 8, flexShrink: 0,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 18, fontWeight: 700, color: TDG_COLORS.priority, flex: 1 }}>Daily Compass Check</span>
          <button onClick={onBack} disabled={step === 0} style={{
            padding: '5px 10px', borderRadius: 6, border: `1px solid ${TDG_COLORS.neutral300}`,
            background: '#fff', fontSize: 13, color: step === 0 ? TDG_COLORS.neutral300 : '#333', cursor: step === 0 ? 'default' : 'pointer',
          }}>Back</button>
          <button onClick={onCancel} style={{
            padding: '5px 10px', borderRadius: 6, border: `1px solid ${TDG_COLORS.neutral300}`,
            background: '#fff', fontSize: 13, color: '#333', cursor: 'pointer',
          }}>Cancel</button>
          <button onClick={onNext} style={{
            padding: '5px 12px', borderRadius: 6, border: 'none',
            background: TDG_COLORS.priority, color: '#fff',
            fontSize: 13, fontWeight: 600, cursor: 'pointer',
          }}>{nextLabel}</button>
        </div>
        {/* Step progress */}
        <div style={{ display: 'flex', gap: 4 }}>
          {Array.from({ length: totalSteps }).map((_, i) => (
            <div key={i} style={{
              flex: 1, height: 3, borderRadius: 2,
              background: i <= step ? TDG_COLORS.priority : TDG_COLORS.neutral200,
              transition: 'background 0.2s',
            }}></div>
          ))}
        </div>
      </div>
      {/* Content */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '16px 14px' }}>
        {stepContent}
      </div>
    </div>
  );
}

// ── Task Detail View ────────────────────────────────────────────────────────
function TaskDetailView({ task, onClose, onStateChange }) {
  const stateColors = {
    priority: TDG_COLORS.priority,
    open: TDG_COLORS.open,
    pending: TDG_COLORS.pending,
    closed: TDG_COLORS.closed,
    dead: TDG_COLORS.dead,
  };
  const stateLabels = { priority: '★ Priority', open: '○ Open', pending: '◷ Pending', closed: '✓ Closed', dead: '⬜ Graveyard' };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
      {/* Title */}
      <div style={{ background: TDG_COLORS.neutral50, border: `1px solid ${TDG_COLORS.neutral200}`, borderRadius: 10, padding: '12px 14px' }}>
        <div style={{ fontSize: 11, fontWeight: 600, color: TDG_COLORS.neutral500, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 4 }}>Title</div>
        <div style={{ fontSize: 16, fontWeight: 500, color: '#111', lineHeight: 1.4 }}>{task.title}</div>
      </div>
      {/* State */}
      <div style={{ background: TDG_COLORS.neutral50, border: `1px solid ${TDG_COLORS.neutral200}`, borderRadius: 10, padding: '10px 14px' }}>
        <div style={{ fontSize: 11, fontWeight: 600, color: TDG_COLORS.neutral500, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 8 }}>State</div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          {Object.entries(stateLabels).map(([s, label]) => (
            <button key={s} onClick={() => onStateChange && onStateChange(s)} style={{
              padding: '4px 10px', borderRadius: 6,
              border: `1px solid ${task.state === s ? stateColors[s] : TDG_COLORS.neutral200}`,
              background: task.state === s ? `${stateColors[s]}18` : '#fff',
              color: task.state === s ? stateColors[s] : '#666',
              fontSize: 12, fontWeight: task.state === s ? 600 : 400, cursor: 'pointer',
            }}>{label}</button>
          ))}
        </div>
      </div>
      {/* Tags */}
      {task.tags && task.tags.length > 0 && (
        <div style={{ background: TDG_COLORS.neutral50, border: `1px solid ${TDG_COLORS.neutral200}`, borderRadius: 10, padding: '10px 14px' }}>
          <div style={{ fontSize: 11, fontWeight: 600, color: TDG_COLORS.neutral500, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 8 }}>Tags</div>
          <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap' }}>
            {task.tags.map(t => <span key={t} style={{ background: TDG_COLORS.accent, color: '#fff', padding: '2px 8px', borderRadius: 4, fontSize: 11, fontWeight: 500 }}>{t}</span>)}
          </div>
        </div>
      )}
      {/* Notes */}
      <div style={{ background: TDG_COLORS.neutral50, border: `1px solid ${TDG_COLORS.neutral200}`, borderRadius: 10, padding: '10px 14px' }}>
        <div style={{ fontSize: 11, fontWeight: 600, color: TDG_COLORS.neutral500, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 4 }}>Notes</div>
        <div style={{ fontSize: 13, color: task.notes ? '#333' : TDG_COLORS.neutral400, fontStyle: task.notes ? 'normal' : 'italic', lineHeight: 1.5, minHeight: 40 }}>
          {task.notes || 'No notes yet…'}
        </div>
      </div>
      {/* History */}
      <div style={{ background: TDG_COLORS.neutral50, border: `1px solid ${TDG_COLORS.neutral200}`, borderRadius: 10, padding: '10px 14px' }}>
        <div style={{ fontSize: 11, fontWeight: 600, color: TDG_COLORS.neutral500, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 6 }}>History</div>
        {(task.history || []).map((h, i) => (
          <div key={i} style={{ display: 'flex', gap: 8, alignItems: 'flex-start', padding: '4px 0', borderBottom: i < (task.history.length - 1) ? `1px solid ${TDG_COLORS.neutral100}` : 'none' }}>
            <span style={{ fontSize: 11, color: TDG_COLORS.neutral400, whiteSpace: 'nowrap' }}>{h.date}</span>
            <span style={{ fontSize: 12, color: '#444' }}>{h.note}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

// Export all to window
Object.assign(window, {
  TDG_COLORS,
  StatusBar,
  NavBar,
  EEMIndicator,
  TaskRow,
  ListContainer,
  StreakWidget,
  SidebarLinks,
  TagChip,
  CompassCheckDialog,
  TaskDetailView,
});
