## 6. UI/UX Runtime Behavior Constraints
1. The Tablet Board viewer MUST use `InteractiveViewer` to support dynamic multi-touch panning and zooming automatically.
2. The Mobile controller interaction MUST follow strict state machine rules: [Idle -> CardSelected -> TargetSelected -> Dispatched].
3. Invalid grid coordinates evaluated by BFS must be highlighted in red/green transparent overlays before final confirmation.
4. Enforce Firestore Transactions for every game action to block concurrent race conditions, and implement UI locking during network pending states.