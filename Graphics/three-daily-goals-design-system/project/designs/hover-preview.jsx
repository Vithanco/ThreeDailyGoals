// Task Hover Preview — Compass Check
const { useState, useRef, useEffect } = React;

const TDG = {
  accent:   '#EA580C',
  priority: '#E6A012',
  open:     '#3B82C4',
  pending:  '#B59A00',
  closed:   '#4A9E6A',
  dead:     '#8C7058',
  dueSoon:  '#D94F47',
  eemDeepWork:  '#B4A5D5',
  eemSteady:    '#7BB8BA',
  eemSprint:    '#F4A89A',
  eemEasyWin:   '#A8D5BA',
};

const QUAD_LABELS = {
  deepWork:  'Deep Work · High energy, Big task',
  sprint:    'Sprint Task · High energy, Small task',
  steady:    'Steady Progress · Low energy, Big task',
  easyWin:   'Easy Win · Low energy, Small task',
};
const QUAD_CHIP = {
  deepWork: { cls: 'eem-deepWork', label: 'Deep Work' },
  sprint:   { cls: 'eem-sprint',   label: 'Sprint' },
  steady:   { cls: 'eem-steady',   label: 'Steady' },
  easyWin:  { cls: 'eem-easyWin',  label: 'Easy Win' },
};

const STATE_CHIP = {
  priority: { cls: 'state-priority', icon: '★', label: 'Priority' },
  open:     { cls: 'state-open',     icon: '○', label: 'Open' },
  pending:  { cls: 'state-pending',  icon: '◷', label: 'Pending' },
  closed:   { cls: 'state-closed',   icon: '✓', label: 'Closed' },
  dead:     { cls: 'state-dead',     icon: '▦', label: 'Graveyard' },
};

const TASKS = [
  {
    id: 1,
    title: 'Quarterly review doc',
    state: 'open', quadrant: 'deepWork',
    due: 'Fri · in 3 days', dueUrgent: false,
    notes: "Include Q2 metrics, the migration retrospective, and the roadmap slide Klaus asked for. Aim for ~6 pages, share with team for comments before Friday.",
    tags: ['work', 'writing'],
    created: 'Apr 28',
    lastTouched: '2 days ago',
    history: [
      { date: 'May 1', note: 'Added energy/effort: Deep Work' },
      { date: 'Apr 30', note: 'Set due date Fri' },
      { date: 'Apr 28', note: 'Added task' },
    ],
  },
  {
    id: 2,
    title: 'Fix login bug',
    state: 'open', quadrant: 'sprint',
    due: 'tomorrow', dueUrgent: true,
    notes: 'Repro: Sign in with Apple → redirects to a blank screen on first launch. Slack thread from Maria has the trace. Probably the keychain race condition again.',
    tags: ['bug', 'work'],
    created: 'May 2',
    lastTouched: 'yesterday',
    history: [
      { date: 'May 8', note: 'Maria added trace logs' },
      { date: 'May 2', note: 'Added task' },
    ],
  },
  {
    id: 3,
    title: 'Reply to Simon',
    state: 'open', quadrant: 'easyWin',
    due: null, dueUrgent: false,
    notes: '',
    tags: ['email'],
    created: 'Apr 30',
    lastTouched: '5 days ago',
    history: [
      { date: 'Apr 30', note: 'Added task' },
    ],
  },
  {
    id: 4,
    title: 'Refactor data layer',
    state: 'open', quadrant: 'steady',
    due: null, dueUrgent: false,
    notes: 'Move SwiftData stack to the new repository pattern. Start with TaskStore — extract the query helpers first, then migrate writes one call site at a time.',
    tags: ['work', 'tech-debt'],
    created: 'Apr 15',
    lastTouched: 'last week',
    history: [
      { date: 'May 3', note: 'Marked as Steady Progress' },
      { date: 'Apr 15', note: 'Added task' },
    ],
  },
  {
    id: 5,
    title: 'Update app icon',
    state: 'open', quadrant: 'sprint',
    due: null, dueUrgent: false,
    notes: '',
    tags: ['design'],
    created: 'Apr 22',
    lastTouched: '3 weeks ago',
    history: [{ date: 'Apr 22', note: 'Added task' }],
  },
  {
    id: 6,
    title: 'Research pricing tiers',
    state: 'open', quadrant: null,
    due: null, dueUrgent: false,
    notes: '',
    tags: [],
    created: 'Mar 30',
    lastTouched: '6 weeks ago',
    history: [{ date: 'Mar 30', note: 'Added task' }],
  },
];

// ── EEM mini quadrant indicator ─────────────────────────────────────────────
function EEM({ q }) {
  const fills = { rgba: 'rgba(0,0,0,0.08)' };
  const cells = ['rgba(0,0,0,0.08)','rgba(0,0,0,0.08)','rgba(0,0,0,0.08)','rgba(0,0,0,0.08)'];
  if (q === 'deepWork') cells[0] = TDG.eemDeepWork;
  if (q === 'sprint')   cells[1] = TDG.eemSprint;
  if (q === 'steady')   cells[2] = TDG.eemSteady;
  if (q === 'easyWin')  cells[3] = TDG.eemEasyWin;
  return (
    <div className="eem" style={{ opacity: q ? 0.9 : 0.4 }}>
      {cells.map((c, i) => <div key={i} style={{ background: c }} />)}
    </div>
  );
}

// ── Hover Preview Card ──────────────────────────────────────────────────────
function HoverPreview({ task, density, showHistory, top }) {
  const stateInfo = STATE_CHIP[task.state];
  const quadInfo  = task.quadrant ? QUAD_CHIP[task.quadrant] : null;
  const hasNotes  = task.notes && task.notes.trim().length > 0;

  return (
    <div className="preview" style={{ left: 'calc(100% + 14px)', top }}>
      <div className="pv-title">{task.title}</div>

      <div className="pv-meta">
        <span className={`pv-chip ${stateInfo.cls}`}>{stateInfo.icon} {stateInfo.label}</span>
        {quadInfo && <span className={`pv-chip ${quadInfo.cls}`}>{quadInfo.label}</span>}
        {task.due && <span className={`pv-chip ${task.dueUrgent ? 'due-urgent' : ''}`}>⌚ {task.due}</span>}
      </div>

      {density !== 'minimal' && (
        <div className="pv-section">
          <div className="pv-section-label">Notes</div>
          <div className={`pv-notes ${hasNotes ? '' : 'empty'}`}>
            {hasNotes ? task.notes : 'No notes yet — add some to remember why this matters.'}
          </div>
        </div>
      )}

      {density === 'rich' && task.tags && task.tags.length > 0 && (
        <div className="pv-section">
          <div className="pv-section-label">Tags</div>
          <div className="pv-tags">
            {task.tags.map(t => <span key={t} className="pv-tag">{t}</span>)}
          </div>
        </div>
      )}

      {showHistory && (
        <div className="pv-section">
          <div className="pv-section-label">Recent activity</div>
          <div className="pv-history">
            {task.history.length === 0
              ? <div className="pv-empty">No activity yet.</div>
              : task.history.slice(0, density === 'rich' ? 3 : 2).map((h, i) => (
                <div key={i} className="pv-history-item">
                  <span className="date">{h.date}</span>
                  <span className="note">{h.note}</span>
                </div>
              ))}
          </div>
        </div>
      )}

      {density === 'rich' && (
        <div className="pv-meta" style={{ marginTop: 10, marginBottom: 0, color: '#888' }}>
          <span>Created {task.created}</span>
          <span>·</span>
          <span>Touched {task.lastTouched}</span>
        </div>
      )}

      <div className="pv-footer">
        <span className="pv-hint"><kbd>Space</kbd> open · <kbd>★</kbd> set priority</span>
      </div>
    </div>
  );
}

// ── Task Row ────────────────────────────────────────────────────────────────
function TaskRow({ task, hovered, onHover, onLeave, rowRef }) {
  const stateInfo = STATE_CHIP[task.state];
  return (
    <div
      ref={rowRef}
      className={`task-row${hovered ? ' hovered' : ''}`}
      onMouseEnter={onHover}
      onMouseLeave={onLeave}
    >
      <EEM q={task.quadrant} />
      <span className="title">{task.title}</span>
      {task.due && (
        <span className={`due ${task.dueUrgent ? 'urgent' : ''}`}>{task.due}</span>
      )}
      <button className="star-btn" title="Set as priority">★</button>
    </div>
  );
}

// ── Root ────────────────────────────────────────────────────────────────────
const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "density": "standard",
  "showHistory": true,
  "lockedHoverId": 1
}/*EDITMODE-END*/;

function CompassCheckStep() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [hoveredId, setHoveredId] = useState(t.lockedHoverId);
  const [previewTop, setPreviewTop] = useState(0);
  const rowRefs = useRef({});
  const bodyRef = useRef(null);

  // Update preview position when hovered task changes
  useEffect(() => {
    if (!hoveredId || !rowRefs.current[hoveredId] || !bodyRef.current) return;
    const rowRect = rowRefs.current[hoveredId].getBoundingClientRect();
    const bodyRect = bodyRef.current.getBoundingClientRect();
    setPreviewTop(rowRect.top - bodyRect.top - 8);
  }, [hoveredId]);

  // Keep the locked task in sync when tweak changes
  useEffect(() => {
    setHoveredId(t.lockedHoverId);
  }, [t.lockedHoverId]);

  const hoveredTask = TASKS.find(x => x.id === hoveredId);

  return (
    <React.Fragment>
      <div ref={bodyRef} style={{ position: 'relative', display: 'flex', flexDirection: 'column', gap: 18 }}>
        <div className="cc-header">
          <div className="compass-icon">◎</div>
          <div>
            <h2>Daily Compass Check</h2>
            <div className="subtitle">Step 3 of 5 · Choose tomorrow's priorities</div>
          </div>
          <div className="cc-progress">
            <div className="done"></div>
            <div className="done"></div>
            <div className="current"></div>
            <div></div>
            <div></div>
          </div>
        </div>

        <div className="step-title">
          <span className="step-num">Step 3</span>
          <h3>Pick up to 3 open tasks for tomorrow</h3>
        </div>
        <p className="step-instructions">
          Star the tasks you'll commit to. Hover any row to see what it's about — notes, last activity, and quadrant.
        </p>

        <div style={{ position: 'relative' }}>
          <div className="task-list">
            {TASKS.map(task => (
              <TaskRow
                key={task.id}
                task={task}
                hovered={hoveredId === task.id}
                onHover={() => { setHoveredId(task.id); setTweak('lockedHoverId', task.id); }}
                onLeave={() => {}}
                rowRef={el => { rowRefs.current[task.id] = el; }}
              />
            ))}
          </div>
          {hoveredTask && (
            <HoverPreview
              task={hoveredTask}
              density={t.density}
              showHistory={t.showHistory}
              top={previewTop}
            />
          )}
        </div>
      </div>

      <TweaksPanel title="Hover Preview Tweaks">
        <TweakSection title="Content density">
          <TweakRadio
            label="Density"
            value={t.density}
            onChange={v => setTweak('density', v)}
            options={[
              { value: 'minimal',  label: 'Minimal' },
              { value: 'standard', label: 'Standard' },
              { value: 'rich',     label: 'Rich' },
            ]}
          />
          <div style={{ fontSize: 11, color: '#888', marginTop: 6, lineHeight: 1.45 }}>
            Minimal: title + chips only.<br/>
            Standard: + notes.<br/>
            Rich: + tags, longer history, created/touched timestamps.
          </div>
          <TweakToggle
            label="Show recent activity"
            checked={t.showHistory}
            onChange={v => setTweak('showHistory', v)}
          />
        </TweakSection>

        <TweakSection title="Preview a task">
          <TweakSelect
            label="Hovered row"
            value={t.lockedHoverId}
            onChange={v => setTweak('lockedHoverId', Number(v))}
            options={TASKS.map(x => ({ value: x.id, label: x.title }))}
          />
          <div style={{ fontSize: 11, color: '#888', marginTop: 6 }}>
            Try the empty-notes one (#3 or #5) to see how the preview handles missing info.
          </div>
        </TweakSection>
      </TweaksPanel>
    </React.Fragment>
  );
}

const root = ReactDOM.createRoot(document.getElementById('cc-root'));
root.render(<CompassCheckStep />);
