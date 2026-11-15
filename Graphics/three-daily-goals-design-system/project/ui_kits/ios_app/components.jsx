// Three Daily Goals — iOS App UI Components
// Shared components exported to window for use in index.html

const { useState } = React;

const TDG_COLORS = {
  accent:   '#EA580C',           // brand orange — keep full strength, it's intentional
  priority: '#E6A012',           // amber/gold — distinct from brand (was #E8900A)
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
function StreakWidget({ streak = 42, done = true, onCompassCheck, onAddTask }) {
  return (
    <div style={{
      background: '#fff',
      border: `1px solid ${TDG_COLORS.neutral200}`,
      borderRadius: 10, padding: '10px 14px',
      boxShadow: 'rgba(0,0,0,0.04) 0px 1px 3px',
      display: 'flex', flexDirection: 'column', gap: 10,
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
      {/* Two primary actions, stacked — Compass Check leads, New Task directly below */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <button onClick={onCompassCheck} style={{
          width: '100%',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          gap: 7, padding: '11px 10px',
          background: TDG_COLORS.accent, color: '#fff',
          border: 'none', borderRadius: 12,
          fontSize: 14, fontWeight: 600, cursor: 'pointer',
        }}>
          <span style={{ fontSize: 15, lineHeight: 1 }}>◎</span> Start Compass Check
        </button>
        <button onClick={onAddTask} style={{
          width: '100%',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          gap: 7, padding: '11px 10px',
          background: TDG_COLORS.open, color: '#fff',
          border: 'none', borderRadius: 12,
          fontSize: 14, fontWeight: 600, cursor: 'pointer',
        }}>
          <span style={{ fontSize: 17, lineHeight: 1, marginTop: -1 }}>＋</span> New Task
        </button>
      </div>
    </div>
  );
}

// ── New Task Sheet ──────────────────────────────────────────────────────────
// iOS-style modal sheet for creating a task. Clear top-right "Add" button is
// the explicit confirm/done — no need to navigate back.
function NewTaskSheet({ onCancel, onAdd }) {
  const [title, setTitle] = useState('');
  const [quadrant, setQuadrant] = useState(null);
  const [due, setDue] = useState(null);
  const [tags, setTags] = useState([]);
  const [notes, setNotes] = useState('');
  const [priority, setPriority] = useState(false);
  const canAdd = title.trim().length > 0;

  const toggleTag = (t) => setTags(prev => prev.includes(t) ? prev.filter(x => x !== t) : [...prev, t]);

  // 2×2 Energy-Effort grid: rows = energy (high/low), cols = effort (big/small)
  const quads = [
    { key: 'deepWork', label: 'Deep Work',       color: TDG_COLORS.eemDeepWork },
    { key: 'sprint',   label: 'Sprint Tasks',    color: TDG_COLORS.eemSprintTasks },
    { key: 'steady',   label: 'Steady Progress', color: TDG_COLORS.eemSteadyProgress },
    { key: 'easyWin',  label: 'Easy Wins',       color: TDG_COLORS.eemEasyWins },
  ];
  const dueOptions = [
    { key: null, label: 'None' },
    { key: 'today', label: 'Today' },
    { key: 'tomorrow', label: 'Tomorrow' },
    { key: 'in 7 days', label: 'This week' },
  ];
  const tagOptions = ['big-task', 'small-task', 'high-energy', 'low-energy'];

  const handleAdd = () => {
    if (!canAdd) return;
    onAdd({
      title: title.trim(),
      quadrant,
      due,
      dueUrgent: due === 'today' || due === 'tomorrow',
      state: priority ? 'priority' : 'open',
      tags,
      notes: notes.trim(),
    });
  };

  const fieldLabel = { fontSize: 11, fontWeight: 600, color: TDG_COLORS.neutral500, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 8 };
  const card = { background: TDG_COLORS.neutral50, border: `1px solid ${TDG_COLORS.neutral200}`, borderRadius: 10, padding: '10px 14px' };

  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 150, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}>
      {/* Dimmed backdrop */}
      <div onClick={onCancel} style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.32)' }}></div>
      {/* Sheet panel */}
      <div style={{
        position: 'relative', background: '#fff',
        borderRadius: '14px 14px 0 0', height: '93%',
        display: 'flex', flexDirection: 'column', overflow: 'hidden',
        boxShadow: '0 -8px 40px rgba(0,0,0,0.25)',
      }}>
        {/* Grabber */}
        <div style={{ display: 'flex', justifyContent: 'center', paddingTop: 8 }}>
          <div style={{ width: 38, height: 5, borderRadius: 3, background: TDG_COLORS.neutral300 }}></div>
        </div>
        {/* Header: Cancel · New Task · Add (the clear Done button) */}
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 14px 12px', borderBottom: `1px solid ${TDG_COLORS.neutral200}` }}>
          <button onClick={onCancel} style={{ background: 'none', border: 'none', color: TDG_COLORS.open, fontSize: 16, cursor: 'pointer', padding: 0, minWidth: 56, textAlign: 'left' }}>Cancel</button>
          <span style={{ flex: 1, textAlign: 'center', fontSize: 17, fontWeight: 700, color: '#111' }}>New Task</span>
          <button onClick={handleAdd} disabled={!canAdd} style={{
            background: 'none', border: 'none', fontSize: 16, fontWeight: 700,
            color: canAdd ? TDG_COLORS.accent : TDG_COLORS.neutral300,
            cursor: canAdd ? 'pointer' : 'default', padding: 0, minWidth: 56, textAlign: 'right',
          }}>Add</button>
        </div>
        {/* Body */}
        <div style={{ flex: 1, overflowY: 'auto', padding: '14px', display: 'flex', flexDirection: 'column', gap: 14 }}>
          {/* Title */}
          <input
            autoFocus
            value={title}
            onChange={e => setTitle(e.target.value)}
            placeholder="What needs doing?"
            style={{
              ...card, fontSize: 16, color: '#111', fontWeight: 500,
              outline: 'none', width: '100%',
            }}
          />
          {/* Make it a priority */}
          <div style={{ ...card, display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer' }} onClick={() => setPriority(p => !p)}>
            <span style={{ color: TDG_COLORS.priority, fontSize: 16 }}>{priority ? '★' : '☆'}</span>
            <span style={{ flex: 1, fontSize: 14, color: '#111' }}>Make one of today's goals</span>
            {/* iOS switch */}
            <div style={{ width: 44, height: 26, borderRadius: 13, background: priority ? TDG_COLORS.closed : TDG_COLORS.neutral300, position: 'relative', transition: 'background 0.15s', flexShrink: 0 }}>
              <div style={{ position: 'absolute', top: 2, left: priority ? 20 : 2, width: 22, height: 22, borderRadius: 11, background: '#fff', boxShadow: '0 1px 3px rgba(0,0,0,0.3)', transition: 'left 0.15s' }}></div>
            </div>
          </div>
          {/* Energy-Effort Matrix */}
          <div style={card}>
            <div style={fieldLabel}>Energy · Effort</div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'stretch' }}>
              {/* Energy axis label */}
              <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', fontSize: 9, color: TDG_COLORS.neutral500, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.04em', padding: '4px 0' }}>
                <span>High</span><span>Low</span>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6 }}>
                  {quads.map(q => {
                    const active = quadrant === q.key;
                    return (
                      <button key={q.key} onClick={() => setQuadrant(active ? null : q.key)} style={{
                        padding: '12px 8px', borderRadius: 8,
                        border: `1.5px solid ${active ? q.color : TDG_COLORS.neutral200}`,
                        background: active ? q.color + '33' : '#fff',
                        cursor: 'pointer', textAlign: 'center',
                        display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 5,
                      }}>
                        <span style={{ width: 12, height: 12, borderRadius: 3, background: q.color }}></span>
                        <span style={{ fontSize: 12, fontWeight: active ? 700 : 500, color: '#333' }}>{q.label}</span>
                      </button>
                    );
                  })}
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 9, color: TDG_COLORS.neutral500, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.04em', marginTop: 5 }}>
                  <span>Big task</span><span>Small task</span>
                </div>
              </div>
            </div>
          </div>
          {/* Due date */}
          <div style={card}>
            <div style={fieldLabel}>Due</div>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              {dueOptions.map(o => {
                const active = due === o.key;
                return (
                  <button key={o.label} onClick={() => setDue(o.key)} style={{
                    padding: '5px 12px', borderRadius: 20,
                    border: `1px solid ${active ? TDG_COLORS.open : TDG_COLORS.neutral300}`,
                    background: active ? TDG_COLORS.open + '18' : '#fff',
                    color: active ? TDG_COLORS.open : '#555',
                    fontSize: 13, fontWeight: active ? 600 : 400, cursor: 'pointer',
                  }}>{o.label}</button>
                );
              })}
            </div>
          </div>
          {/* Tags */}
          <div style={card}>
            <div style={fieldLabel}>Tags</div>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              {tagOptions.map(t => (
                <TagChip key={t} label={t} active={tags.includes(t)} onToggle={() => toggleTag(t)} />
              ))}
            </div>
          </div>
          {/* Notes */}
          <div style={card}>
            <div style={fieldLabel}>Notes</div>
            <textarea
              value={notes}
              onChange={e => setNotes(e.target.value)}
              placeholder="Add a note…"
              rows={3}
              style={{
                width: '100%', border: 'none', outline: 'none', resize: 'none',
                background: 'transparent', fontSize: 14, color: '#333', lineHeight: 1.5,
                fontFamily: 'inherit',
              }}
            />
          </div>
        </div>
      </div>
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
function TagChip({ label, active, color = TDG_COLORS.accent, onToggle }) {
  return (
    <button onClick={onToggle} style={{
      padding: '4px 11px', borderRadius: 4,
      border: `1px solid ${active ? color : 'rgba(234,88,12,0.28)'}`,
      background: active ? color : 'rgba(234,88,12,0.09)',
      color: active ? '#fff' : '#B4500F',
      fontSize: 12, fontWeight: active ? 600 : 500,
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
  NewTaskSheet,
});
