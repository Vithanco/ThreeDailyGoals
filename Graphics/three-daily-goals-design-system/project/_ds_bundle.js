/* @ds-bundle: {"format":3,"namespace":"ThreeDailyGoalsDesignSystem_019ded","components":[],"sourceHashes":{"designs/hover-preview.jsx":"b1e8813ef6b5","designs/tweaks-panel.jsx":"a1107c630a56","ui_kits/ios_app/components.jsx":"b26acde92f6f"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.ThreeDailyGoalsDesignSystem_019ded = window.ThreeDailyGoalsDesignSystem_019ded || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// designs/hover-preview.jsx
try { (() => {
// Task Hover Preview — Compass Check
const {
  useState,
  useRef,
  useEffect
} = React;
const TDG = {
  accent: '#EA580C',
  priority: '#E6A012',
  open: '#3B82C4',
  pending: '#B59A00',
  closed: '#4A9E6A',
  dead: '#8C7058',
  dueSoon: '#D94F47',
  eemDeepWork: '#B4A5D5',
  eemSteady: '#7BB8BA',
  eemSprint: '#F4A89A',
  eemEasyWin: '#A8D5BA'
};
const QUAD_LABELS = {
  deepWork: 'Deep Work · High energy, Big task',
  sprint: 'Sprint Task · High energy, Small task',
  steady: 'Steady Progress · Low energy, Big task',
  easyWin: 'Easy Win · Low energy, Small task'
};
const QUAD_CHIP = {
  deepWork: {
    cls: 'eem-deepWork',
    label: 'Deep Work'
  },
  sprint: {
    cls: 'eem-sprint',
    label: 'Sprint'
  },
  steady: {
    cls: 'eem-steady',
    label: 'Steady'
  },
  easyWin: {
    cls: 'eem-easyWin',
    label: 'Easy Win'
  }
};
const STATE_CHIP = {
  priority: {
    cls: 'state-priority',
    icon: '★',
    label: 'Priority'
  },
  open: {
    cls: 'state-open',
    icon: '○',
    label: 'Open'
  },
  pending: {
    cls: 'state-pending',
    icon: '◷',
    label: 'Pending'
  },
  closed: {
    cls: 'state-closed',
    icon: '✓',
    label: 'Closed'
  },
  dead: {
    cls: 'state-dead',
    icon: '▦',
    label: 'Graveyard'
  }
};
const TASKS = [{
  id: 1,
  title: 'Quarterly review doc',
  state: 'open',
  quadrant: 'deepWork',
  due: 'Fri · in 3 days',
  dueUrgent: false,
  notes: "Include Q2 metrics, the migration retrospective, and the roadmap slide Klaus asked for. Aim for ~6 pages, share with team for comments before Friday.",
  tags: ['work', 'writing'],
  created: 'Apr 28',
  lastTouched: '2 days ago',
  history: [{
    date: 'May 1',
    note: 'Added energy/effort: Deep Work'
  }, {
    date: 'Apr 30',
    note: 'Set due date Fri'
  }, {
    date: 'Apr 28',
    note: 'Added task'
  }]
}, {
  id: 2,
  title: 'Fix login bug',
  state: 'open',
  quadrant: 'sprint',
  due: 'tomorrow',
  dueUrgent: true,
  notes: 'Repro: Sign in with Apple → redirects to a blank screen on first launch. Slack thread from Maria has the trace. Probably the keychain race condition again.',
  tags: ['bug', 'work'],
  created: 'May 2',
  lastTouched: 'yesterday',
  history: [{
    date: 'May 8',
    note: 'Maria added trace logs'
  }, {
    date: 'May 2',
    note: 'Added task'
  }]
}, {
  id: 3,
  title: 'Reply to Simon',
  state: 'open',
  quadrant: 'easyWin',
  due: null,
  dueUrgent: false,
  notes: '',
  tags: ['email'],
  created: 'Apr 30',
  lastTouched: '5 days ago',
  history: [{
    date: 'Apr 30',
    note: 'Added task'
  }]
}, {
  id: 4,
  title: 'Refactor data layer',
  state: 'open',
  quadrant: 'steady',
  due: null,
  dueUrgent: false,
  notes: 'Move SwiftData stack to the new repository pattern. Start with TaskStore — extract the query helpers first, then migrate writes one call site at a time.',
  tags: ['work', 'tech-debt'],
  created: 'Apr 15',
  lastTouched: 'last week',
  history: [{
    date: 'May 3',
    note: 'Marked as Steady Progress'
  }, {
    date: 'Apr 15',
    note: 'Added task'
  }]
}, {
  id: 5,
  title: 'Update app icon',
  state: 'open',
  quadrant: 'sprint',
  due: null,
  dueUrgent: false,
  notes: '',
  tags: ['design'],
  created: 'Apr 22',
  lastTouched: '3 weeks ago',
  history: [{
    date: 'Apr 22',
    note: 'Added task'
  }]
}, {
  id: 6,
  title: 'Research pricing tiers',
  state: 'open',
  quadrant: null,
  due: null,
  dueUrgent: false,
  notes: '',
  tags: [],
  created: 'Mar 30',
  lastTouched: '6 weeks ago',
  history: [{
    date: 'Mar 30',
    note: 'Added task'
  }]
}];

// ── EEM mini quadrant indicator ─────────────────────────────────────────────
function EEM({
  q
}) {
  const fills = {
    rgba: 'rgba(0,0,0,0.08)'
  };
  const cells = ['rgba(0,0,0,0.08)', 'rgba(0,0,0,0.08)', 'rgba(0,0,0,0.08)', 'rgba(0,0,0,0.08)'];
  if (q === 'deepWork') cells[0] = TDG.eemDeepWork;
  if (q === 'sprint') cells[1] = TDG.eemSprint;
  if (q === 'steady') cells[2] = TDG.eemSteady;
  if (q === 'easyWin') cells[3] = TDG.eemEasyWin;
  return /*#__PURE__*/React.createElement("div", {
    className: "eem",
    style: {
      opacity: q ? 0.9 : 0.4
    }
  }, cells.map((c, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      background: c
    }
  })));
}

// ── Hover Preview Card ──────────────────────────────────────────────────────
function HoverPreview({
  task,
  density,
  showHistory,
  top
}) {
  const stateInfo = STATE_CHIP[task.state];
  const quadInfo = task.quadrant ? QUAD_CHIP[task.quadrant] : null;
  const hasNotes = task.notes && task.notes.trim().length > 0;
  return /*#__PURE__*/React.createElement("div", {
    className: "preview",
    style: {
      left: 'calc(100% + 14px)',
      top
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "pv-title"
  }, task.title), /*#__PURE__*/React.createElement("div", {
    className: "pv-meta"
  }, /*#__PURE__*/React.createElement("span", {
    className: `pv-chip ${stateInfo.cls}`
  }, stateInfo.icon, " ", stateInfo.label), quadInfo && /*#__PURE__*/React.createElement("span", {
    className: `pv-chip ${quadInfo.cls}`
  }, quadInfo.label), task.due && /*#__PURE__*/React.createElement("span", {
    className: `pv-chip ${task.dueUrgent ? 'due-urgent' : ''}`
  }, "\u231A ", task.due)), density !== 'minimal' && /*#__PURE__*/React.createElement("div", {
    className: "pv-section"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pv-section-label"
  }, "Notes"), /*#__PURE__*/React.createElement("div", {
    className: `pv-notes ${hasNotes ? '' : 'empty'}`
  }, hasNotes ? task.notes : 'No notes yet — add some to remember why this matters.')), density === 'rich' && task.tags && task.tags.length > 0 && /*#__PURE__*/React.createElement("div", {
    className: "pv-section"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pv-section-label"
  }, "Tags"), /*#__PURE__*/React.createElement("div", {
    className: "pv-tags"
  }, task.tags.map(t => /*#__PURE__*/React.createElement("span", {
    key: t,
    className: "pv-tag"
  }, t)))), showHistory && /*#__PURE__*/React.createElement("div", {
    className: "pv-section"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pv-section-label"
  }, "Recent activity"), /*#__PURE__*/React.createElement("div", {
    className: "pv-history"
  }, task.history.length === 0 ? /*#__PURE__*/React.createElement("div", {
    className: "pv-empty"
  }, "No activity yet.") : task.history.slice(0, density === 'rich' ? 3 : 2).map((h, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    className: "pv-history-item"
  }, /*#__PURE__*/React.createElement("span", {
    className: "date"
  }, h.date), /*#__PURE__*/React.createElement("span", {
    className: "note"
  }, h.note))))), density === 'rich' && /*#__PURE__*/React.createElement("div", {
    className: "pv-meta",
    style: {
      marginTop: 10,
      marginBottom: 0,
      color: '#888'
    }
  }, /*#__PURE__*/React.createElement("span", null, "Created ", task.created), /*#__PURE__*/React.createElement("span", null, "\xB7"), /*#__PURE__*/React.createElement("span", null, "Touched ", task.lastTouched)), /*#__PURE__*/React.createElement("div", {
    className: "pv-footer"
  }, /*#__PURE__*/React.createElement("span", {
    className: "pv-hint"
  }, /*#__PURE__*/React.createElement("kbd", null, "Space"), " open \xB7 ", /*#__PURE__*/React.createElement("kbd", null, "\u2605"), " set priority")));
}

// ── Task Row ────────────────────────────────────────────────────────────────
function TaskRow({
  task,
  hovered,
  onHover,
  onLeave,
  rowRef
}) {
  const stateInfo = STATE_CHIP[task.state];
  return /*#__PURE__*/React.createElement("div", {
    ref: rowRef,
    className: `task-row${hovered ? ' hovered' : ''}`,
    onMouseEnter: onHover,
    onMouseLeave: onLeave
  }, /*#__PURE__*/React.createElement(EEM, {
    q: task.quadrant
  }), /*#__PURE__*/React.createElement("span", {
    className: "title"
  }, task.title), task.due && /*#__PURE__*/React.createElement("span", {
    className: `due ${task.dueUrgent ? 'urgent' : ''}`
  }, task.due), /*#__PURE__*/React.createElement("button", {
    className: "star-btn",
    title: "Set as priority"
  }, "\u2605"));
}

// ── Root ────────────────────────────────────────────────────────────────────
const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "density": "standard",
  "showHistory": true,
  "lockedHoverId": 1
} /*EDITMODE-END*/;
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
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
    ref: bodyRef,
    style: {
      position: 'relative',
      display: 'flex',
      flexDirection: 'column',
      gap: 18
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "cc-header"
  }, /*#__PURE__*/React.createElement("div", {
    className: "compass-icon"
  }, "\u25CE"), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("h2", null, "Daily Compass Check"), /*#__PURE__*/React.createElement("div", {
    className: "subtitle"
  }, "Step 3 of 5 \xB7 Choose tomorrow's priorities")), /*#__PURE__*/React.createElement("div", {
    className: "cc-progress"
  }, /*#__PURE__*/React.createElement("div", {
    className: "done"
  }), /*#__PURE__*/React.createElement("div", {
    className: "done"
  }), /*#__PURE__*/React.createElement("div", {
    className: "current"
  }), /*#__PURE__*/React.createElement("div", null), /*#__PURE__*/React.createElement("div", null))), /*#__PURE__*/React.createElement("div", {
    className: "step-title"
  }, /*#__PURE__*/React.createElement("span", {
    className: "step-num"
  }, "Step 3"), /*#__PURE__*/React.createElement("h3", null, "Pick up to 3 open tasks for tomorrow")), /*#__PURE__*/React.createElement("p", {
    className: "step-instructions"
  }, "Star the tasks you'll commit to. Hover any row to see what it's about \u2014 notes, last activity, and quadrant."), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative'
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "task-list"
  }, TASKS.map(task => /*#__PURE__*/React.createElement(TaskRow, {
    key: task.id,
    task: task,
    hovered: hoveredId === task.id,
    onHover: () => {
      setHoveredId(task.id);
      setTweak('lockedHoverId', task.id);
    },
    onLeave: () => {},
    rowRef: el => {
      rowRefs.current[task.id] = el;
    }
  }))), hoveredTask && /*#__PURE__*/React.createElement(HoverPreview, {
    task: hoveredTask,
    density: t.density,
    showHistory: t.showHistory,
    top: previewTop
  }))), /*#__PURE__*/React.createElement(TweaksPanel, {
    title: "Hover Preview Tweaks"
  }, /*#__PURE__*/React.createElement(TweakSection, {
    title: "Content density"
  }, /*#__PURE__*/React.createElement(TweakRadio, {
    label: "Density",
    value: t.density,
    onChange: v => setTweak('density', v),
    options: [{
      value: 'minimal',
      label: 'Minimal'
    }, {
      value: 'standard',
      label: 'Standard'
    }, {
      value: 'rich',
      label: 'Rich'
    }]
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      color: '#888',
      marginTop: 6,
      lineHeight: 1.45
    }
  }, "Minimal: title + chips only.", /*#__PURE__*/React.createElement("br", null), "Standard: + notes.", /*#__PURE__*/React.createElement("br", null), "Rich: + tags, longer history, created/touched timestamps."), /*#__PURE__*/React.createElement(TweakToggle, {
    label: "Show recent activity",
    checked: t.showHistory,
    onChange: v => setTweak('showHistory', v)
  })), /*#__PURE__*/React.createElement(TweakSection, {
    title: "Preview a task"
  }, /*#__PURE__*/React.createElement(TweakSelect, {
    label: "Hovered row",
    value: t.lockedHoverId,
    onChange: v => setTweak('lockedHoverId', Number(v)),
    options: TASKS.map(x => ({
      value: x.id,
      label: x.title
    }))
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      color: '#888',
      marginTop: 6
    }
  }, "Try the empty-notes one (#3 or #5) to see how the preview handles missing info."))));
}
const root = ReactDOM.createRoot(document.getElementById('cc-root'));
root.render(/*#__PURE__*/React.createElement(CompassCheckStep, null));
})(); } catch (e) { __ds_ns.__errors.push({ path: "designs/hover-preview.jsx", error: String((e && e.message) || e) }); }

// designs/tweaks-panel.jsx
try { (() => {
// tweaks-panel.jsx
// Reusable Tweaks shell + form-control helpers.
//
// Owns the host protocol (listens for __activate_edit_mode / __deactivate_edit_mode,
// posts __edit_mode_available / __edit_mode_set_keys / __edit_mode_dismissed) so
// individual prototypes don't re-roll it. Ships a consistent set of controls so you
// don't hand-draw <input type="range">, segmented radios, steppers, etc.
//
// Usage (in an HTML file that loads React + Babel):
//
//   const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
//     "primaryColor": "#D97757",
//     "palette": ["#D97757", "#29261b", "#f6f4ef"],
//     "fontSize": 16,
//     "density": "regular",
//     "dark": false
//   }/*EDITMODE-END*/;
//
//   function App() {
//     const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
//     return (
//       <div style={{ fontSize: t.fontSize, color: t.primaryColor }}>
//         Hello
//         <TweaksPanel>
//           <TweakSection label="Typography" />
//           <TweakSlider label="Font size" value={t.fontSize} min={10} max={32} unit="px"
//                        onChange={(v) => setTweak('fontSize', v)} />
//           <TweakRadio  label="Density" value={t.density}
//                        options={['compact', 'regular', 'comfy']}
//                        onChange={(v) => setTweak('density', v)} />
//           <TweakSection label="Theme" />
//           <TweakColor  label="Primary" value={t.primaryColor}
//                        options={['#D97757', '#2A6FDB', '#1F8A5B', '#7A5AE0']}
//                        onChange={(v) => setTweak('primaryColor', v)} />
//           <TweakColor  label="Palette" value={t.palette}
//                        options={[['#D97757', '#29261b', '#f6f4ef'],
//                                  ['#475569', '#0f172a', '#f1f5f9']]}
//                        onChange={(v) => setTweak('palette', v)} />
//           <TweakToggle label="Dark mode" value={t.dark}
//                        onChange={(v) => setTweak('dark', v)} />
//         </TweaksPanel>
//       </div>
//     );
//   }
//
// ─────────────────────────────────────────────────────────────────────────────

const __TWEAKS_STYLE = `
  .twk-panel{position:fixed;right:16px;bottom:16px;z-index:2147483646;width:280px;
    max-height:calc(100vh - 32px);display:flex;flex-direction:column;
    transform:scale(var(--dc-inv-zoom,1));transform-origin:bottom right;
    background:rgba(250,249,247,.78);color:#29261b;
    -webkit-backdrop-filter:blur(24px) saturate(160%);backdrop-filter:blur(24px) saturate(160%);
    border:.5px solid rgba(255,255,255,.6);border-radius:14px;
    box-shadow:0 1px 0 rgba(255,255,255,.5) inset,0 12px 40px rgba(0,0,0,.18);
    font:11.5px/1.4 ui-sans-serif,system-ui,-apple-system,sans-serif;overflow:hidden}
  .twk-hd{display:flex;align-items:center;justify-content:space-between;
    padding:10px 8px 10px 14px;cursor:move;user-select:none}
  .twk-hd b{font-size:12px;font-weight:600;letter-spacing:.01em}
  .twk-x{appearance:none;border:0;background:transparent;color:rgba(41,38,27,.55);
    width:22px;height:22px;border-radius:6px;cursor:default;font-size:13px;line-height:1}
  .twk-x:hover{background:rgba(0,0,0,.06);color:#29261b}
  .twk-body{padding:2px 14px 14px;display:flex;flex-direction:column;gap:10px;
    overflow-y:auto;overflow-x:hidden;min-height:0;
    scrollbar-width:thin;scrollbar-color:rgba(0,0,0,.15) transparent}
  .twk-body::-webkit-scrollbar{width:8px}
  .twk-body::-webkit-scrollbar-track{background:transparent;margin:2px}
  .twk-body::-webkit-scrollbar-thumb{background:rgba(0,0,0,.15);border-radius:4px;
    border:2px solid transparent;background-clip:content-box}
  .twk-body::-webkit-scrollbar-thumb:hover{background:rgba(0,0,0,.25);
    border:2px solid transparent;background-clip:content-box}
  .twk-row{display:flex;flex-direction:column;gap:5px}
  .twk-row-h{flex-direction:row;align-items:center;justify-content:space-between;gap:10px}
  .twk-lbl{display:flex;justify-content:space-between;align-items:baseline;
    color:rgba(41,38,27,.72)}
  .twk-lbl>span:first-child{font-weight:500}
  .twk-val{color:rgba(41,38,27,.5);font-variant-numeric:tabular-nums}

  .twk-sect{font-size:10px;font-weight:600;letter-spacing:.06em;text-transform:uppercase;
    color:rgba(41,38,27,.45);padding:10px 0 0}
  .twk-sect:first-child{padding-top:0}

  .twk-field{appearance:none;width:100%;height:26px;padding:0 8px;
    border:.5px solid rgba(0,0,0,.1);border-radius:7px;
    background:rgba(255,255,255,.6);color:inherit;font:inherit;outline:none}
  .twk-field:focus{border-color:rgba(0,0,0,.25);background:rgba(255,255,255,.85)}
  select.twk-field{padding-right:22px;
    background-image:url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='10' height='6' viewBox='0 0 10 6'><path fill='rgba(0,0,0,.5)' d='M0 0h10L5 6z'/></svg>");
    background-repeat:no-repeat;background-position:right 8px center}

  .twk-slider{appearance:none;-webkit-appearance:none;width:100%;height:4px;margin:6px 0;
    border-radius:999px;background:rgba(0,0,0,.12);outline:none}
  .twk-slider::-webkit-slider-thumb{-webkit-appearance:none;appearance:none;
    width:14px;height:14px;border-radius:50%;background:#fff;
    border:.5px solid rgba(0,0,0,.12);box-shadow:0 1px 3px rgba(0,0,0,.2);cursor:default}
  .twk-slider::-moz-range-thumb{width:14px;height:14px;border-radius:50%;
    background:#fff;border:.5px solid rgba(0,0,0,.12);box-shadow:0 1px 3px rgba(0,0,0,.2);cursor:default}

  .twk-seg{position:relative;display:flex;padding:2px;border-radius:8px;
    background:rgba(0,0,0,.06);user-select:none}
  .twk-seg-thumb{position:absolute;top:2px;bottom:2px;border-radius:6px;
    background:rgba(255,255,255,.9);box-shadow:0 1px 2px rgba(0,0,0,.12);
    transition:left .15s cubic-bezier(.3,.7,.4,1),width .15s}
  .twk-seg.dragging .twk-seg-thumb{transition:none}
  .twk-seg button{appearance:none;position:relative;z-index:1;flex:1;border:0;
    background:transparent;color:inherit;font:inherit;font-weight:500;min-height:22px;
    border-radius:6px;cursor:default;padding:4px 6px;line-height:1.2;
    overflow-wrap:anywhere}

  .twk-toggle{position:relative;width:32px;height:18px;border:0;border-radius:999px;
    background:rgba(0,0,0,.15);transition:background .15s;cursor:default;padding:0}
  .twk-toggle[data-on="1"]{background:#34c759}
  .twk-toggle i{position:absolute;top:2px;left:2px;width:14px;height:14px;border-radius:50%;
    background:#fff;box-shadow:0 1px 2px rgba(0,0,0,.25);transition:transform .15s}
  .twk-toggle[data-on="1"] i{transform:translateX(14px)}

  .twk-num{display:flex;align-items:center;height:26px;padding:0 0 0 8px;
    border:.5px solid rgba(0,0,0,.1);border-radius:7px;background:rgba(255,255,255,.6)}
  .twk-num-lbl{font-weight:500;color:rgba(41,38,27,.6);cursor:ew-resize;
    user-select:none;padding-right:8px}
  .twk-num input{flex:1;min-width:0;height:100%;border:0;background:transparent;
    font:inherit;font-variant-numeric:tabular-nums;text-align:right;padding:0 8px 0 0;
    outline:none;color:inherit;-moz-appearance:textfield}
  .twk-num input::-webkit-inner-spin-button,.twk-num input::-webkit-outer-spin-button{
    -webkit-appearance:none;margin:0}
  .twk-num-unit{padding-right:8px;color:rgba(41,38,27,.45)}

  .twk-btn{appearance:none;height:26px;padding:0 12px;border:0;border-radius:7px;
    background:rgba(0,0,0,.78);color:#fff;font:inherit;font-weight:500;cursor:default}
  .twk-btn:hover{background:rgba(0,0,0,.88)}
  .twk-btn.secondary{background:rgba(0,0,0,.06);color:inherit}
  .twk-btn.secondary:hover{background:rgba(0,0,0,.1)}

  .twk-swatch{appearance:none;-webkit-appearance:none;width:56px;height:22px;
    border:.5px solid rgba(0,0,0,.1);border-radius:6px;padding:0;cursor:default;
    background:transparent;flex-shrink:0}
  .twk-swatch::-webkit-color-swatch-wrapper{padding:0}
  .twk-swatch::-webkit-color-swatch{border:0;border-radius:5.5px}
  .twk-swatch::-moz-color-swatch{border:0;border-radius:5.5px}

  .twk-chips{display:flex;gap:6px}
  .twk-chip{position:relative;appearance:none;flex:1;min-width:0;height:46px;
    padding:0;border:0;border-radius:6px;overflow:hidden;cursor:default;
    box-shadow:0 0 0 .5px rgba(0,0,0,.12),0 1px 2px rgba(0,0,0,.06);
    transition:transform .12s cubic-bezier(.3,.7,.4,1),box-shadow .12s}
  .twk-chip:hover{transform:translateY(-1px);
    box-shadow:0 0 0 .5px rgba(0,0,0,.18),0 4px 10px rgba(0,0,0,.12)}
  .twk-chip[data-on="1"]{box-shadow:0 0 0 1.5px rgba(0,0,0,.85),
    0 2px 6px rgba(0,0,0,.15)}
  .twk-chip>span{position:absolute;top:0;bottom:0;right:0;width:34%;
    display:flex;flex-direction:column;box-shadow:-1px 0 0 rgba(0,0,0,.1)}
  .twk-chip>span>i{flex:1;box-shadow:0 -1px 0 rgba(0,0,0,.1)}
  .twk-chip>span>i:first-child{box-shadow:none}
  .twk-chip svg{position:absolute;top:6px;left:6px;width:13px;height:13px;
    filter:drop-shadow(0 1px 1px rgba(0,0,0,.3))}
`;

// ── useTweaks ───────────────────────────────────────────────────────────────
// Single source of truth for tweak values. setTweak persists via the host
// (__edit_mode_set_keys → host rewrites the EDITMODE block on disk).
function useTweaks(defaults) {
  const [values, setValues] = React.useState(defaults);
  // Accepts either setTweak('key', value) or setTweak({ key: value, ... }) so a
  // useState-style call doesn't write a "[object Object]" key into the persisted
  // JSON block.
  const setTweak = React.useCallback((keyOrEdits, val) => {
    const edits = typeof keyOrEdits === 'object' && keyOrEdits !== null ? keyOrEdits : {
      [keyOrEdits]: val
    };
    setValues(prev => ({
      ...prev,
      ...edits
    }));
    window.parent.postMessage({
      type: '__edit_mode_set_keys',
      edits
    }, '*');
    // Same-window signal so in-page listeners (deck-stage rail thumbnails)
    // can react — the parent message only reaches the host, not peers.
    window.dispatchEvent(new CustomEvent('tweakchange', {
      detail: edits
    }));
  }, []);
  return [values, setTweak];
}

// ── TweaksPanel ─────────────────────────────────────────────────────────────
// Floating shell. Registers the protocol listener BEFORE announcing
// availability — if the announce ran first, the host's activate could land
// before our handler exists and the toolbar toggle would silently no-op.
// The close button posts __edit_mode_dismissed so the host's toolbar toggle
// flips off in lockstep; the host echoes __deactivate_edit_mode back which
// is what actually hides the panel.
function TweaksPanel({
  title = 'Tweaks',
  noDeckControls = false,
  children
}) {
  const [open, setOpen] = React.useState(false);
  const dragRef = React.useRef(null);
  // Auto-inject a rail toggle when a <deck-stage> is on the page. The
  // toggle drives the deck's per-viewer _railVisible via window message;
  // state is mirrored from the same localStorage key the deck reads so
  // the control reflects reality across reloads. The mechanism is the
  // message — authors who want custom placement can post it directly
  // and pass noDeckControls to suppress this one.
  const hasDeckStage = React.useMemo(() => typeof document !== 'undefined' && !!document.querySelector('deck-stage'), []);
  // Hide the toggle until the host has actually enabled the rail (the
  // __omelette_rail_enabled window message, posted only when the
  // omelette_deck_rail_enabled flag is on for this user). The initial read
  // covers TweaksPanel mounting after the message already arrived; the
  // listener covers the common case of mounting first.
  const [railEnabled, setRailEnabled] = React.useState(() => hasDeckStage && !!document.querySelector('deck-stage')?._railEnabled);
  React.useEffect(() => {
    if (!hasDeckStage || railEnabled) return undefined;
    const onMsg = e => {
      if (e.data && e.data.type === '__omelette_rail_enabled') setRailEnabled(true);
    };
    window.addEventListener('message', onMsg);
    return () => window.removeEventListener('message', onMsg);
  }, [hasDeckStage, railEnabled]);
  const [railVisible, setRailVisible] = React.useState(() => {
    try {
      return localStorage.getItem('deck-stage.railVisible') !== '0';
    } catch (e) {
      return true;
    }
  });
  const toggleRail = on => {
    setRailVisible(on);
    window.postMessage({
      type: '__deck_rail_visible',
      on
    }, '*');
  };
  const offsetRef = React.useRef({
    x: 16,
    y: 16
  });
  const PAD = 16;
  const clampToViewport = React.useCallback(() => {
    const panel = dragRef.current;
    if (!panel) return;
    const w = panel.offsetWidth,
      h = panel.offsetHeight;
    const maxRight = Math.max(PAD, window.innerWidth - w - PAD);
    const maxBottom = Math.max(PAD, window.innerHeight - h - PAD);
    offsetRef.current = {
      x: Math.min(maxRight, Math.max(PAD, offsetRef.current.x)),
      y: Math.min(maxBottom, Math.max(PAD, offsetRef.current.y))
    };
    panel.style.right = offsetRef.current.x + 'px';
    panel.style.bottom = offsetRef.current.y + 'px';
  }, []);
  React.useEffect(() => {
    if (!open) return;
    clampToViewport();
    if (typeof ResizeObserver === 'undefined') {
      window.addEventListener('resize', clampToViewport);
      return () => window.removeEventListener('resize', clampToViewport);
    }
    const ro = new ResizeObserver(clampToViewport);
    ro.observe(document.documentElement);
    return () => ro.disconnect();
  }, [open, clampToViewport]);
  React.useEffect(() => {
    const onMsg = e => {
      const t = e?.data?.type;
      if (t === '__activate_edit_mode') setOpen(true);else if (t === '__deactivate_edit_mode') setOpen(false);
    };
    window.addEventListener('message', onMsg);
    window.parent.postMessage({
      type: '__edit_mode_available'
    }, '*');
    return () => window.removeEventListener('message', onMsg);
  }, []);
  const dismiss = () => {
    setOpen(false);
    window.parent.postMessage({
      type: '__edit_mode_dismissed'
    }, '*');
  };
  const onDragStart = e => {
    const panel = dragRef.current;
    if (!panel) return;
    const r = panel.getBoundingClientRect();
    const sx = e.clientX,
      sy = e.clientY;
    const startRight = window.innerWidth - r.right;
    const startBottom = window.innerHeight - r.bottom;
    const move = ev => {
      offsetRef.current = {
        x: startRight - (ev.clientX - sx),
        y: startBottom - (ev.clientY - sy)
      };
      clampToViewport();
    };
    const up = () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', up);
    };
    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
  };
  if (!open) return null;
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("style", null, __TWEAKS_STYLE), /*#__PURE__*/React.createElement("div", {
    ref: dragRef,
    className: "twk-panel",
    "data-noncommentable": "",
    style: {
      right: offsetRef.current.x,
      bottom: offsetRef.current.y
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-hd",
    onMouseDown: onDragStart
  }, /*#__PURE__*/React.createElement("b", null, title), /*#__PURE__*/React.createElement("button", {
    className: "twk-x",
    "aria-label": "Close tweaks",
    onMouseDown: e => e.stopPropagation(),
    onClick: dismiss
  }, "\u2715")), /*#__PURE__*/React.createElement("div", {
    className: "twk-body"
  }, children, hasDeckStage && railEnabled && !noDeckControls && /*#__PURE__*/React.createElement(TweakSection, {
    label: "Deck"
  }, /*#__PURE__*/React.createElement(TweakToggle, {
    label: "Thumbnail rail",
    value: railVisible,
    onChange: toggleRail
  })))));
}

// ── Layout helpers ──────────────────────────────────────────────────────────

function TweakSection({
  label,
  children
}) {
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
    className: "twk-sect"
  }, label), children);
}
function TweakRow({
  label,
  value,
  children,
  inline = false
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: inline ? 'twk-row twk-row-h' : 'twk-row'
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-lbl"
  }, /*#__PURE__*/React.createElement("span", null, label), value != null && /*#__PURE__*/React.createElement("span", {
    className: "twk-val"
  }, value)), children);
}

// ── Controls ────────────────────────────────────────────────────────────────

function TweakSlider({
  label,
  value,
  min = 0,
  max = 100,
  step = 1,
  unit = '',
  onChange
}) {
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label,
    value: `${value}${unit}`
  }, /*#__PURE__*/React.createElement("input", {
    type: "range",
    className: "twk-slider",
    min: min,
    max: max,
    step: step,
    value: value,
    onChange: e => onChange(Number(e.target.value))
  }));
}
function TweakToggle({
  label,
  value,
  onChange
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: "twk-row twk-row-h"
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-lbl"
  }, /*#__PURE__*/React.createElement("span", null, label)), /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: "twk-toggle",
    "data-on": value ? '1' : '0',
    role: "switch",
    "aria-checked": !!value,
    onClick: () => onChange(!value)
  }, /*#__PURE__*/React.createElement("i", null)));
}
function TweakRadio({
  label,
  value,
  options,
  onChange
}) {
  const trackRef = React.useRef(null);
  const [dragging, setDragging] = React.useState(false);
  // The active value is read by pointer-move handlers attached for the lifetime
  // of a drag — ref it so a stale closure doesn't fire onChange for every move.
  const valueRef = React.useRef(value);
  valueRef.current = value;

  // Segments wrap mid-word once per-segment width runs out. The track is
  // ~248px (280 panel − 28 body pad − 4 seg pad), each button loses 12px
  // to its own padding, and 11.5px system-ui averages ~6.3px/char — so 2
  // options fit ~16 chars each, 3 fit ~10. Past that (or >3 options), fall
  // back to a dropdown rather than wrap.
  const labelLen = o => String(typeof o === 'object' ? o.label : o).length;
  const maxLen = options.reduce((m, o) => Math.max(m, labelLen(o)), 0);
  const fitsAsSegments = maxLen <= ({
    2: 16,
    3: 10
  }[options.length] ?? 0);
  if (!fitsAsSegments) {
    // <select> emits strings — map back to the original option value so the
    // fallback stays type-preserving (numbers, booleans) like the segment path.
    const resolve = s => {
      const m = options.find(o => String(typeof o === 'object' ? o.value : o) === s);
      return m === undefined ? s : typeof m === 'object' ? m.value : m;
    };
    return /*#__PURE__*/React.createElement(TweakSelect, {
      label: label,
      value: value,
      options: options,
      onChange: s => onChange(resolve(s))
    });
  }
  const opts = options.map(o => typeof o === 'object' ? o : {
    value: o,
    label: o
  });
  const idx = Math.max(0, opts.findIndex(o => o.value === value));
  const n = opts.length;
  const segAt = clientX => {
    const r = trackRef.current.getBoundingClientRect();
    const inner = r.width - 4;
    const i = Math.floor((clientX - r.left - 2) / inner * n);
    return opts[Math.max(0, Math.min(n - 1, i))].value;
  };
  const onPointerDown = e => {
    setDragging(true);
    const v0 = segAt(e.clientX);
    if (v0 !== valueRef.current) onChange(v0);
    const move = ev => {
      if (!trackRef.current) return;
      const v = segAt(ev.clientX);
      if (v !== valueRef.current) onChange(v);
    };
    const up = () => {
      setDragging(false);
      window.removeEventListener('pointermove', move);
      window.removeEventListener('pointerup', up);
    };
    window.addEventListener('pointermove', move);
    window.addEventListener('pointerup', up);
  };
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label
  }, /*#__PURE__*/React.createElement("div", {
    ref: trackRef,
    role: "radiogroup",
    onPointerDown: onPointerDown,
    className: dragging ? 'twk-seg dragging' : 'twk-seg'
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-seg-thumb",
    style: {
      left: `calc(2px + ${idx} * (100% - 4px) / ${n})`,
      width: `calc((100% - 4px) / ${n})`
    }
  }), opts.map(o => /*#__PURE__*/React.createElement("button", {
    key: o.value,
    type: "button",
    role: "radio",
    "aria-checked": o.value === value
  }, o.label))));
}
function TweakSelect({
  label,
  value,
  options,
  onChange
}) {
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label
  }, /*#__PURE__*/React.createElement("select", {
    className: "twk-field",
    value: value,
    onChange: e => onChange(e.target.value)
  }, options.map(o => {
    const v = typeof o === 'object' ? o.value : o;
    const l = typeof o === 'object' ? o.label : o;
    return /*#__PURE__*/React.createElement("option", {
      key: v,
      value: v
    }, l);
  })));
}
function TweakText({
  label,
  value,
  placeholder,
  onChange
}) {
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label
  }, /*#__PURE__*/React.createElement("input", {
    className: "twk-field",
    type: "text",
    value: value,
    placeholder: placeholder,
    onChange: e => onChange(e.target.value)
  }));
}
function TweakNumber({
  label,
  value,
  min,
  max,
  step = 1,
  unit = '',
  onChange
}) {
  const clamp = n => {
    if (min != null && n < min) return min;
    if (max != null && n > max) return max;
    return n;
  };
  const startRef = React.useRef({
    x: 0,
    val: 0
  });
  const onScrubStart = e => {
    e.preventDefault();
    startRef.current = {
      x: e.clientX,
      val: value
    };
    const decimals = (String(step).split('.')[1] || '').length;
    const move = ev => {
      const dx = ev.clientX - startRef.current.x;
      const raw = startRef.current.val + dx * step;
      const snapped = Math.round(raw / step) * step;
      onChange(clamp(Number(snapped.toFixed(decimals))));
    };
    const up = () => {
      window.removeEventListener('pointermove', move);
      window.removeEventListener('pointerup', up);
    };
    window.addEventListener('pointermove', move);
    window.addEventListener('pointerup', up);
  };
  return /*#__PURE__*/React.createElement("div", {
    className: "twk-num"
  }, /*#__PURE__*/React.createElement("span", {
    className: "twk-num-lbl",
    onPointerDown: onScrubStart
  }, label), /*#__PURE__*/React.createElement("input", {
    type: "number",
    value: value,
    min: min,
    max: max,
    step: step,
    onChange: e => onChange(clamp(Number(e.target.value)))
  }), unit && /*#__PURE__*/React.createElement("span", {
    className: "twk-num-unit"
  }, unit));
}

// Relative-luminance contrast pick — checkmarks drawn over a swatch need to
// read on both #111 and #fafafa without per-option configuration. Hex input
// only (#rgb / #rrggbb); named or rgb()/hsl() colors fall through to "light".
function __twkIsLight(hex) {
  const h = String(hex).replace('#', '');
  const x = h.length === 3 ? h.replace(/./g, c => c + c) : h.padEnd(6, '0');
  const n = parseInt(x.slice(0, 6), 16);
  if (Number.isNaN(n)) return true;
  const r = n >> 16 & 255,
    g = n >> 8 & 255,
    b = n & 255;
  return r * 299 + g * 587 + b * 114 > 148000;
}
const __TwkCheck = ({
  light
}) => /*#__PURE__*/React.createElement("svg", {
  viewBox: "0 0 14 14",
  "aria-hidden": "true"
}, /*#__PURE__*/React.createElement("path", {
  d: "M3 7.2 5.8 10 11 4.2",
  fill: "none",
  strokeWidth: "2.2",
  strokeLinecap: "round",
  strokeLinejoin: "round",
  stroke: light ? 'rgba(0,0,0,.78)' : '#fff'
}));

// TweakColor — curated color/palette picker. Each option is either a single
// hex string or an array of 1-5 hex strings; the card adapts — a lone color
// renders solid, a palette renders colors[0] as the hero (left ~2/3) with the
// rest stacked in a sharp column on the right. onChange emits the
// option in the shape it was passed (string stays string, array stays array).
// Without options it falls back to the native color input for back-compat.
function TweakColor({
  label,
  value,
  options,
  onChange
}) {
  if (!options || !options.length) {
    return /*#__PURE__*/React.createElement("div", {
      className: "twk-row twk-row-h"
    }, /*#__PURE__*/React.createElement("div", {
      className: "twk-lbl"
    }, /*#__PURE__*/React.createElement("span", null, label)), /*#__PURE__*/React.createElement("input", {
      type: "color",
      className: "twk-swatch",
      value: value,
      onChange: e => onChange(e.target.value)
    }));
  }
  // Native <input type=color> emits lowercase hex per the HTML spec, so
  // compare case-insensitively. String() guards JSON.stringify(undefined),
  // which returns the primitive undefined (no .toLowerCase).
  const key = o => String(JSON.stringify(o)).toLowerCase();
  const cur = key(value);
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-chips",
    role: "radiogroup"
  }, options.map((o, i) => {
    const colors = Array.isArray(o) ? o : [o];
    const [hero, ...rest] = colors;
    const sup = rest.slice(0, 4);
    const on = key(o) === cur;
    return /*#__PURE__*/React.createElement("button", {
      key: i,
      type: "button",
      className: "twk-chip",
      role: "radio",
      "aria-checked": on,
      "data-on": on ? '1' : '0',
      "aria-label": colors.join(', '),
      title: colors.join(' · '),
      style: {
        background: hero
      },
      onClick: () => onChange(o)
    }, sup.length > 0 && /*#__PURE__*/React.createElement("span", null, sup.map((c, j) => /*#__PURE__*/React.createElement("i", {
      key: j,
      style: {
        background: c
      }
    }))), on && /*#__PURE__*/React.createElement(__TwkCheck, {
      light: __twkIsLight(hero)
    }));
  })));
}
function TweakButton({
  label,
  onClick,
  secondary = false
}) {
  return /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: secondary ? 'twk-btn secondary' : 'twk-btn',
    onClick: onClick
  }, label);
}
Object.assign(window, {
  useTweaks,
  TweaksPanel,
  TweakSection,
  TweakRow,
  TweakSlider,
  TweakToggle,
  TweakRadio,
  TweakSelect,
  TweakText,
  TweakNumber,
  TweakColor,
  TweakButton
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "designs/tweaks-panel.jsx", error: String((e && e.message) || e) }); }

// ui_kits/ios_app/components.jsx
try { (() => {
// Three Daily Goals — iOS App UI Components
// Shared components exported to window for use in index.html

const {
  useState
} = React;
const TDG_COLORS = {
  accent: '#EA580C',
  // brand orange — keep full strength, it's intentional
  priority: '#E6A012',
  // amber/gold — distinct from brand (was #E8900A)
  open: '#3B82C4',
  // muted blue (was #007AFF)
  pending: '#B59A00',
  // muted gold (was #CCAA00)
  closed: '#4A9E6A',
  // muted green (was #34C759)
  dead: '#8C7058',
  // muted brown (was #A2845E)
  dueSoon: '#D94F47',
  // softer red (was #FF3B30)
  neutral50: '#FAFAFA',
  neutral100: '#F5F5F5',
  neutral200: '#E8E8E8',
  // slightly warmer
  neutral300: '#D8D8D8',
  neutral500: '#9A9A9A',
  neutral700: '#5E5E5E',
  neutral800: '#404040',
  eemDeepWork: '#B4A5D5',
  // unchanged — already muted
  eemSteadyProgress: '#7BB8BA',
  eemSprintTasks: '#F4A89A',
  eemEasyWins: '#A8D5BA'
};
const compStyles = {
  phone: {
    width: 393,
    height: 852,
    background: '#F2F2F7',
    borderRadius: 44,
    overflow: 'hidden',
    position: 'relative',
    fontFamily: 'ui-sans-serif, system-ui, -apple-system, sans-serif',
    boxShadow: '0 30px 80px rgba(0,0,0,0.35), 0 0 0 1px rgba(0,0,0,0.15)',
    display: 'flex',
    flexDirection: 'column',
    flexShrink: 0
  }
};

// ── Status Bar ──────────────────────────────────────────────────────────────
function StatusBar({
  dark = false
}) {
  const color = dark ? '#fff' : '#000';
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: 54,
      display: 'flex',
      alignItems: 'flex-end',
      justifyContent: 'space-between',
      padding: '0 24px 8px',
      background: 'transparent',
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 15,
      fontWeight: 700,
      color
    }
  }, "9:41"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6,
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      color
    }
  }, "\u25CF\u25CF\u25CF"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      color
    }
  }, "WiFi"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      color
    }
  }, "\u2B1B")));
}

// ── Navigation Bar ──────────────────────────────────────────────────────────
function NavBar({
  title,
  leftItems,
  rightItems,
  tintColor = TDG_COLORS.open,
  bg = '#F2F2F7'
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: 44,
      background: bg,
      borderBottom: `1px solid ${TDG_COLORS.neutral200}`,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '0 14px',
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 10,
      minWidth: 60
    }
  }, leftItems), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 17,
      fontWeight: 600,
      color: '#000',
      flex: 1,
      textAlign: 'center'
    }
  }, title), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 12,
      minWidth: 60,
      justifyContent: 'flex-end',
      alignItems: 'center'
    }
  }, rightItems));
}

// ── EEM Quadrant Indicator ──────────────────────────────────────────────────
function EEMIndicator({
  quadrant
}) {
  // quadrant: 'deepWork' | 'sprint' | 'steady' | 'easyWin' | null
  const colors = {
    deepWork: [TDG_COLORS.eemDeepWork, 'rgba(0,0,0,0.1)', 'rgba(0,0,0,0.1)', 'rgba(0,0,0,0.1)'],
    sprint: ['rgba(0,0,0,0.1)', TDG_COLORS.eemSprintTasks, 'rgba(0,0,0,0.1)', 'rgba(0,0,0,0.1)'],
    steady: ['rgba(0,0,0,0.1)', 'rgba(0,0,0,0.1)', TDG_COLORS.eemSteadyProgress, 'rgba(0,0,0,0.1)'],
    easyWin: ['rgba(0,0,0,0.1)', 'rgba(0,0,0,0.1)', 'rgba(0,0,0,0.1)', TDG_COLORS.eemEasyWins]
  };
  const quads = quadrant ? colors[quadrant] : ['rgba(0,0,0,0.08)', 'rgba(0,0,0,0.08)', 'rgba(0,0,0,0.08)', 'rgba(0,0,0,0.08)'];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '1fr 1fr',
      gridTemplateRows: '1fr 1fr',
      gap: 1,
      width: 18,
      height: 18,
      flexShrink: 0,
      opacity: quadrant ? 0.85 : 0.3
    }
  }, quads.map((c, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      background: c,
      borderRadius: 1
    }
  })));
}

// ── Task Row ────────────────────────────────────────────────────────────────
function TaskRow({
  title,
  quadrant = null,
  due = null,
  dueUrgent = false,
  onTap
}) {
  return /*#__PURE__*/React.createElement("div", {
    onClick: onTap,
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      background: '#fff',
      border: `1px solid ${TDG_COLORS.neutral200}`,
      borderRadius: 8,
      padding: '9px 10px',
      boxShadow: 'rgba(0,0,0,0.04) 0px 1px 3px',
      cursor: 'pointer',
      userSelect: 'none'
    }
  }, /*#__PURE__*/React.createElement(EEMIndicator, {
    quadrant: quadrant
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      fontSize: 14,
      color: '#111',
      lineHeight: 1.4
    }
  }, title), due && /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 11,
      color: dueUrgent ? TDG_COLORS.dueSoon : TDG_COLORS.neutral500,
      fontStyle: 'italic',
      flexShrink: 0
    }
  }, due));
}

// ── List Container ──────────────────────────────────────────────────────────
function ListContainer({
  state,
  children,
  count
}) {
  const stateConfig = {
    priority: {
      color: TDG_COLORS.priority,
      icon: '★',
      label: 'Today\'s Goals'
    },
    open: {
      color: TDG_COLORS.open,
      icon: '○',
      label: 'Open'
    },
    pending: {
      color: TDG_COLORS.pending,
      icon: '◷',
      label: 'Pending'
    },
    closed: {
      color: TDG_COLORS.closed,
      icon: '●',
      label: 'Closed'
    },
    dead: {
      color: TDG_COLORS.dead,
      icon: '▦',
      label: 'Graveyard'
    }
  };
  const cfg = stateConfig[state] || stateConfig.open;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 5
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 6,
      padding: '2px 4px'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: cfg.color,
      fontSize: 16
    }
  }, cfg.icon), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 16,
      fontWeight: 700,
      color: '#111'
    }
  }, cfg.label), count != null && /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 12,
      fontWeight: 600,
      color: cfg.color,
      background: `${cfg.color}18`,
      padding: '1px 7px',
      borderRadius: 10
    }
  }, count)), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 5
    }
  }, children));
}

// ── Streak Widget ───────────────────────────────────────────────────────────
function StreakWidget({
  streak = 42,
  done = true,
  onCompassCheck,
  onAddTask
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      background: '#fff',
      border: `1px solid ${TDG_COLORS.neutral200}`,
      borderRadius: 10,
      padding: '10px 14px',
      boxShadow: 'rgba(0,0,0,0.04) 0px 1px 3px',
      display: 'flex',
      flexDirection: 'column',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 5,
      fontSize: 14
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontWeight: 700,
      fontSize: 15
    }
  }, streak), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 15
    }
  }, "\uD83D\uDD25"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontWeight: 500,
      color: '#333',
      fontSize: 13
    }
  }, "Today:"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 16,
      color: done ? TDG_COLORS.closed : TDG_COLORS.open,
      fontWeight: 700
    }
  }, done ? '✓' : '○')), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement("button", {
    onClick: onCompassCheck,
    style: {
      width: '100%',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 7,
      padding: '11px 10px',
      background: TDG_COLORS.accent,
      color: '#fff',
      border: 'none',
      borderRadius: 12,
      fontSize: 14,
      fontWeight: 600,
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 15,
      lineHeight: 1
    }
  }, "\u25CE"), " Start Compass Check"), /*#__PURE__*/React.createElement("button", {
    onClick: onAddTask,
    style: {
      width: '100%',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 7,
      padding: '11px 10px',
      background: TDG_COLORS.open,
      color: '#fff',
      border: 'none',
      borderRadius: 12,
      fontSize: 14,
      fontWeight: 600,
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 17,
      lineHeight: 1,
      marginTop: -1
    }
  }, "\uFF0B"), " New Task")));
}

// ── New Task Sheet ──────────────────────────────────────────────────────────
// iOS-style modal sheet for creating a task. Clear top-right "Add" button is
// the explicit confirm/done — no need to navigate back.
function NewTaskSheet({
  onCancel,
  onAdd
}) {
  const [title, setTitle] = useState('');
  const [quadrant, setQuadrant] = useState(null);
  const [due, setDue] = useState(null);
  const [tags, setTags] = useState([]);
  const [notes, setNotes] = useState('');
  const [priority, setPriority] = useState(false);
  const canAdd = title.trim().length > 0;
  const toggleTag = t => setTags(prev => prev.includes(t) ? prev.filter(x => x !== t) : [...prev, t]);

  // 2×2 Energy-Effort grid: rows = energy (high/low), cols = effort (big/small)
  const quads = [{
    key: 'deepWork',
    label: 'Deep Work',
    color: TDG_COLORS.eemDeepWork
  }, {
    key: 'sprint',
    label: 'Sprint Tasks',
    color: TDG_COLORS.eemSprintTasks
  }, {
    key: 'steady',
    label: 'Steady Progress',
    color: TDG_COLORS.eemSteadyProgress
  }, {
    key: 'easyWin',
    label: 'Easy Wins',
    color: TDG_COLORS.eemEasyWins
  }];
  const dueOptions = [{
    key: null,
    label: 'None'
  }, {
    key: 'today',
    label: 'Today'
  }, {
    key: 'tomorrow',
    label: 'Tomorrow'
  }, {
    key: 'in 7 days',
    label: 'This week'
  }];
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
      notes: notes.trim()
    });
  };
  const fieldLabel = {
    fontSize: 11,
    fontWeight: 600,
    color: TDG_COLORS.neutral500,
    textTransform: 'uppercase',
    letterSpacing: '0.05em',
    marginBottom: 8
  };
  const card = {
    background: TDG_COLORS.neutral50,
    border: `1px solid ${TDG_COLORS.neutral200}`,
    borderRadius: 10,
    padding: '10px 14px'
  };
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      zIndex: 150,
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'flex-end'
    }
  }, /*#__PURE__*/React.createElement("div", {
    onClick: onCancel,
    style: {
      position: 'absolute',
      inset: 0,
      background: 'rgba(0,0,0,0.32)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      background: '#fff',
      borderRadius: '14px 14px 0 0',
      height: '93%',
      display: 'flex',
      flexDirection: 'column',
      overflow: 'hidden',
      boxShadow: '0 -8px 40px rgba(0,0,0,0.25)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'center',
      paddingTop: 8
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 38,
      height: 5,
      borderRadius: 3,
      background: TDG_COLORS.neutral300
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      padding: '10px 14px 12px',
      borderBottom: `1px solid ${TDG_COLORS.neutral200}`
    }
  }, /*#__PURE__*/React.createElement("button", {
    onClick: onCancel,
    style: {
      background: 'none',
      border: 'none',
      color: TDG_COLORS.open,
      fontSize: 16,
      cursor: 'pointer',
      padding: 0,
      minWidth: 56,
      textAlign: 'left'
    }
  }, "Cancel"), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      textAlign: 'center',
      fontSize: 17,
      fontWeight: 700,
      color: '#111'
    }
  }, "New Task"), /*#__PURE__*/React.createElement("button", {
    onClick: handleAdd,
    disabled: !canAdd,
    style: {
      background: 'none',
      border: 'none',
      fontSize: 16,
      fontWeight: 700,
      color: canAdd ? TDG_COLORS.accent : TDG_COLORS.neutral300,
      cursor: canAdd ? 'pointer' : 'default',
      padding: 0,
      minWidth: 56,
      textAlign: 'right'
    }
  }, "Add")), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      padding: '14px',
      display: 'flex',
      flexDirection: 'column',
      gap: 14
    }
  }, /*#__PURE__*/React.createElement("input", {
    autoFocus: true,
    value: title,
    onChange: e => setTitle(e.target.value),
    placeholder: "What needs doing?",
    style: {
      ...card,
      fontSize: 16,
      color: '#111',
      fontWeight: 500,
      outline: 'none',
      width: '100%'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      ...card,
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      cursor: 'pointer'
    },
    onClick: () => setPriority(p => !p)
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: TDG_COLORS.priority,
      fontSize: 16
    }
  }, priority ? '★' : '☆'), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      fontSize: 14,
      color: '#111'
    }
  }, "Make one of today's goals"), /*#__PURE__*/React.createElement("div", {
    style: {
      width: 44,
      height: 26,
      borderRadius: 13,
      background: priority ? TDG_COLORS.closed : TDG_COLORS.neutral300,
      position: 'relative',
      transition: 'background 0.15s',
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 2,
      left: priority ? 20 : 2,
      width: 22,
      height: 22,
      borderRadius: 11,
      background: '#fff',
      boxShadow: '0 1px 3px rgba(0,0,0,0.3)',
      transition: 'left 0.15s'
    }
  }))), /*#__PURE__*/React.createElement("div", {
    style: card
  }, /*#__PURE__*/React.createElement("div", {
    style: fieldLabel
  }, "Energy \xB7 Effort"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      alignItems: 'stretch'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'space-between',
      fontSize: 9,
      color: TDG_COLORS.neutral500,
      fontWeight: 600,
      textTransform: 'uppercase',
      letterSpacing: '0.04em',
      padding: '4px 0'
    }
  }, /*#__PURE__*/React.createElement("span", null, "High"), /*#__PURE__*/React.createElement("span", null, "Low")), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '1fr 1fr',
      gap: 6
    }
  }, quads.map(q => {
    const active = quadrant === q.key;
    return /*#__PURE__*/React.createElement("button", {
      key: q.key,
      onClick: () => setQuadrant(active ? null : q.key),
      style: {
        padding: '12px 8px',
        borderRadius: 8,
        border: `1.5px solid ${active ? q.color : TDG_COLORS.neutral200}`,
        background: active ? q.color + '33' : '#fff',
        cursor: 'pointer',
        textAlign: 'center',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 5
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 12,
        height: 12,
        borderRadius: 3,
        background: q.color
      }
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 12,
        fontWeight: active ? 700 : 500,
        color: '#333'
      }
    }, q.label));
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      fontSize: 9,
      color: TDG_COLORS.neutral500,
      fontWeight: 600,
      textTransform: 'uppercase',
      letterSpacing: '0.04em',
      marginTop: 5
    }
  }, /*#__PURE__*/React.createElement("span", null, "Big task"), /*#__PURE__*/React.createElement("span", null, "Small task"))))), /*#__PURE__*/React.createElement("div", {
    style: card
  }, /*#__PURE__*/React.createElement("div", {
    style: fieldLabel
  }, "Due"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6,
      flexWrap: 'wrap'
    }
  }, dueOptions.map(o => {
    const active = due === o.key;
    return /*#__PURE__*/React.createElement("button", {
      key: o.label,
      onClick: () => setDue(o.key),
      style: {
        padding: '5px 12px',
        borderRadius: 20,
        border: `1px solid ${active ? TDG_COLORS.open : TDG_COLORS.neutral300}`,
        background: active ? TDG_COLORS.open + '18' : '#fff',
        color: active ? TDG_COLORS.open : '#555',
        fontSize: 13,
        fontWeight: active ? 600 : 400,
        cursor: 'pointer'
      }
    }, o.label);
  }))), /*#__PURE__*/React.createElement("div", {
    style: card
  }, /*#__PURE__*/React.createElement("div", {
    style: fieldLabel
  }, "Tags"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6,
      flexWrap: 'wrap'
    }
  }, tagOptions.map(t => /*#__PURE__*/React.createElement(TagChip, {
    key: t,
    label: t,
    active: tags.includes(t),
    onToggle: () => toggleTag(t)
  })))), /*#__PURE__*/React.createElement("div", {
    style: card
  }, /*#__PURE__*/React.createElement("div", {
    style: fieldLabel
  }, "Notes"), /*#__PURE__*/React.createElement("textarea", {
    value: notes,
    onChange: e => setNotes(e.target.value),
    placeholder: "Add a note\u2026",
    rows: 3,
    style: {
      width: '100%',
      border: 'none',
      outline: 'none',
      resize: 'none',
      background: 'transparent',
      fontSize: 14,
      color: '#333',
      lineHeight: 1.5,
      fontFamily: 'inherit'
    }
  })))));
}

// ── Sidebar List Links ──────────────────────────────────────────────────────
function SidebarLinks({
  active,
  onSelect
}) {
  const lists = [{
    key: 'open',
    icon: '○',
    label: 'Open',
    color: TDG_COLORS.open,
    count: 29
  }, {
    key: 'pending',
    icon: '◷',
    label: 'Pending Response',
    color: TDG_COLORS.pending,
    count: 1
  }, {
    key: 'closed',
    icon: '●',
    label: 'Closed',
    color: TDG_COLORS.closed,
    count: null
  }, {
    key: 'dead',
    icon: '▦',
    label: 'Graveyard',
    color: TDG_COLORS.dead,
    count: null
  }];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 3
    }
  }, lists.map(l => /*#__PURE__*/React.createElement("div", {
    key: l.key,
    onClick: () => onSelect && onSelect(l.key),
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      padding: '10px 12px',
      borderRadius: 10,
      cursor: 'pointer',
      background: active === l.key ? '#fff' : '#fff',
      border: active === l.key ? `1.5px solid ${l.color}` : `1px solid ${TDG_COLORS.neutral200}`,
      boxShadow: active === l.key ? `rgba(0,0,0,0.06) 0px 1px 4px` : 'none',
      transition: 'border 0.15s, box-shadow 0.15s'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 3,
      height: 28,
      borderRadius: 2,
      background: l.color,
      flexShrink: 0,
      alignSelf: 'center'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      fontSize: 15,
      fontWeight: active === l.key ? 600 : 400,
      color: active === l.key ? l.color : '#111'
    }
  }, l.label), l.count != null && /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 12,
      fontWeight: 600,
      color: active === l.key ? '#fff' : l.color,
      background: active === l.key ? l.color : `${l.color}22`,
      padding: '2px 8px',
      borderRadius: 10,
      minWidth: 24,
      textAlign: 'center'
    }
  }, l.count))));
}

// ── Tag Chips ───────────────────────────────────────────────────────────────
function TagChip({
  label,
  active,
  color = TDG_COLORS.accent,
  onToggle
}) {
  return /*#__PURE__*/React.createElement("button", {
    onClick: onToggle,
    style: {
      padding: '4px 11px',
      borderRadius: 4,
      border: `1px solid ${active ? color : 'rgba(234,88,12,0.28)'}`,
      background: active ? color : 'rgba(234,88,12,0.09)',
      color: active ? '#fff' : '#B4500F',
      fontSize: 12,
      fontWeight: active ? 600 : 500,
      cursor: 'pointer'
    }
  }, label);
}

// ── Compass Check Dialog ────────────────────────────────────────────────────
function CompassCheckDialog({
  step,
  totalSteps,
  stepTitle,
  stepContent,
  onBack,
  onNext,
  onCancel,
  nextLabel = 'Next'
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      background: '#fff',
      zIndex: 100,
      display: 'flex',
      flexDirection: 'column'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '16px 12px 8px',
      borderBottom: `1px solid ${TDG_COLORS.neutral200}`,
      display: 'flex',
      flexDirection: 'column',
      gap: 8,
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 18,
      fontWeight: 700,
      color: TDG_COLORS.priority,
      flex: 1
    }
  }, "Daily Compass Check"), /*#__PURE__*/React.createElement("button", {
    onClick: onBack,
    disabled: step === 0,
    style: {
      padding: '5px 10px',
      borderRadius: 6,
      border: `1px solid ${TDG_COLORS.neutral300}`,
      background: '#fff',
      fontSize: 13,
      color: step === 0 ? TDG_COLORS.neutral300 : '#333',
      cursor: step === 0 ? 'default' : 'pointer'
    }
  }, "Back"), /*#__PURE__*/React.createElement("button", {
    onClick: onCancel,
    style: {
      padding: '5px 10px',
      borderRadius: 6,
      border: `1px solid ${TDG_COLORS.neutral300}`,
      background: '#fff',
      fontSize: 13,
      color: '#333',
      cursor: 'pointer'
    }
  }, "Cancel"), /*#__PURE__*/React.createElement("button", {
    onClick: onNext,
    style: {
      padding: '5px 12px',
      borderRadius: 6,
      border: 'none',
      background: TDG_COLORS.priority,
      color: '#fff',
      fontSize: 13,
      fontWeight: 600,
      cursor: 'pointer'
    }
  }, nextLabel)), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 4
    }
  }, Array.from({
    length: totalSteps
  }).map((_, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      flex: 1,
      height: 3,
      borderRadius: 2,
      background: i <= step ? TDG_COLORS.priority : TDG_COLORS.neutral200,
      transition: 'background 0.2s'
    }
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      padding: '16px 14px'
    }
  }, stepContent));
}

// ── Task Detail View ────────────────────────────────────────────────────────
function TaskDetailView({
  task,
  onClose,
  onStateChange
}) {
  const stateColors = {
    priority: TDG_COLORS.priority,
    open: TDG_COLORS.open,
    pending: TDG_COLORS.pending,
    closed: TDG_COLORS.closed,
    dead: TDG_COLORS.dead
  };
  const stateLabels = {
    priority: '★ Priority',
    open: '○ Open',
    pending: '◷ Pending',
    closed: '✓ Closed',
    dead: '⬜ Graveyard'
  };
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 14
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      background: TDG_COLORS.neutral50,
      border: `1px solid ${TDG_COLORS.neutral200}`,
      borderRadius: 10,
      padding: '12px 14px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      fontWeight: 600,
      color: TDG_COLORS.neutral500,
      textTransform: 'uppercase',
      letterSpacing: '0.05em',
      marginBottom: 4
    }
  }, "Title"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 16,
      fontWeight: 500,
      color: '#111',
      lineHeight: 1.4
    }
  }, task.title)), /*#__PURE__*/React.createElement("div", {
    style: {
      background: TDG_COLORS.neutral50,
      border: `1px solid ${TDG_COLORS.neutral200}`,
      borderRadius: 10,
      padding: '10px 14px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      fontWeight: 600,
      color: TDG_COLORS.neutral500,
      textTransform: 'uppercase',
      letterSpacing: '0.05em',
      marginBottom: 8
    }
  }, "State"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6,
      flexWrap: 'wrap'
    }
  }, Object.entries(stateLabels).map(([s, label]) => /*#__PURE__*/React.createElement("button", {
    key: s,
    onClick: () => onStateChange && onStateChange(s),
    style: {
      padding: '4px 10px',
      borderRadius: 6,
      border: `1px solid ${task.state === s ? stateColors[s] : TDG_COLORS.neutral200}`,
      background: task.state === s ? `${stateColors[s]}18` : '#fff',
      color: task.state === s ? stateColors[s] : '#666',
      fontSize: 12,
      fontWeight: task.state === s ? 600 : 400,
      cursor: 'pointer'
    }
  }, label)))), task.tags && task.tags.length > 0 && /*#__PURE__*/React.createElement("div", {
    style: {
      background: TDG_COLORS.neutral50,
      border: `1px solid ${TDG_COLORS.neutral200}`,
      borderRadius: 10,
      padding: '10px 14px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      fontWeight: 600,
      color: TDG_COLORS.neutral500,
      textTransform: 'uppercase',
      letterSpacing: '0.05em',
      marginBottom: 8
    }
  }, "Tags"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 5,
      flexWrap: 'wrap'
    }
  }, task.tags.map(t => /*#__PURE__*/React.createElement("span", {
    key: t,
    style: {
      background: TDG_COLORS.accent,
      color: '#fff',
      padding: '2px 8px',
      borderRadius: 4,
      fontSize: 11,
      fontWeight: 500
    }
  }, t)))), /*#__PURE__*/React.createElement("div", {
    style: {
      background: TDG_COLORS.neutral50,
      border: `1px solid ${TDG_COLORS.neutral200}`,
      borderRadius: 10,
      padding: '10px 14px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      fontWeight: 600,
      color: TDG_COLORS.neutral500,
      textTransform: 'uppercase',
      letterSpacing: '0.05em',
      marginBottom: 4
    }
  }, "Notes"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: task.notes ? '#333' : TDG_COLORS.neutral400,
      fontStyle: task.notes ? 'normal' : 'italic',
      lineHeight: 1.5,
      minHeight: 40
    }
  }, task.notes || 'No notes yet…')), /*#__PURE__*/React.createElement("div", {
    style: {
      background: TDG_COLORS.neutral50,
      border: `1px solid ${TDG_COLORS.neutral200}`,
      borderRadius: 10,
      padding: '10px 14px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      fontWeight: 600,
      color: TDG_COLORS.neutral500,
      textTransform: 'uppercase',
      letterSpacing: '0.05em',
      marginBottom: 6
    }
  }, "History"), (task.history || []).map((h, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      display: 'flex',
      gap: 8,
      alignItems: 'flex-start',
      padding: '4px 0',
      borderBottom: i < task.history.length - 1 ? `1px solid ${TDG_COLORS.neutral100}` : 'none'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 11,
      color: TDG_COLORS.neutral400,
      whiteSpace: 'nowrap'
    }
  }, h.date), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 12,
      color: '#444'
    }
  }, h.note)))));
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
  NewTaskSheet
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/ios_app/components.jsx", error: String((e && e.message) || e) }); }

})();
