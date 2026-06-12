export class PlannerTimer {
  constructor(tasks, onUpdate) {
    this.tasks = tasks;
    this.done = Array(tasks.length).fill(false);
    this.onUpdate = onUpdate;
    this.state = {
      index: this._findNext(),
      running: false,
      remaining: 0,
      timerId: null,
      startedAt: null
    };
    this.state.remaining = tasks[this.state.index]?.duration ?? 0;
  }

  _findNext(from = 0) {
    for (let i = from; i < this.tasks.length; i++) {
      if (!this.done[i]) return i;
    }
    return this.tasks.length;
  }

  static fmtSec(s) {
    s = Math.max(0, s);
    const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), sec = s % 60;
    if (h > 0) return `${h}:${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`;
    return `${m}:${String(sec).padStart(2, '0')}`;
  }

  static fmtMin(s) {
    return `${Math.max(0, Math.round(s / 60))}分`;
  }

  _sync() {
    if (!this.state.running) return;
    const now = Date.now();
    if (this.state.startedAt == null) { this.state.startedAt = now; return; }
    const elapsed = Math.floor((now - this.state.startedAt) / 1000);
    this.state.remaining = Math.max(0, this.state.remaining - elapsed);
    this.state.startedAt = now;
  }

  _tick() {
    this._sync();
    if (this.state.running && this.state.remaining <= 0) { this.next(true); return; }
    this.onUpdate();
  }

  start() {
    if (this.state.index >= this.tasks.length) return;
    if (this.state.remaining <= 0) { this.next(true); return; }
    if (!this.state.running) {
      this.state.running = true;
      this.state.startedAt = Date.now();
      this.state.timerId = setInterval(() => this._tick(), 1000);
      this.onUpdate();
    }
  }

  pause() {
    if (!this.state.running) return;
    this._sync();
    this.state.running = false;
    this.state.startedAt = null;
    clearInterval(this.state.timerId);
    this.state.timerId = null;
    this.onUpdate();
  }

  next(auto = false) {
    if (this.state.index >= this.tasks.length) return;
    clearInterval(this.state.timerId);
    this.state.timerId = null;
    this.done[this.state.index] = true;
    this.state.startedAt = null;
    this.state.index = this._findNext(this.state.index + 1);
    this.state.remaining = this.tasks[this.state.index]?.duration ?? 0;
    if (this.state.index >= this.tasks.length) {
      this.state.running = false;
    } else if (auto) {
      this.state.running = true;
      this.state.startedAt = Date.now();
      this.state.timerId = setInterval(() => this._tick(), 1000);
    } else {
      this.state.running = false;
    }
    this.onUpdate();
  }

  reset() {
    clearInterval(this.state.timerId);
    this.done.fill(false);
    this.state.index = this._findNext();
    this.state.running = false;
    this.state.remaining = this.tasks[this.state.index]?.duration ?? 0;
    this.state.startedAt = null;
    this.state.timerId = null;
    this.onUpdate();
  }

  toggle(index, checked) {
    this.done[index] = checked;
    clearInterval(this.state.timerId);
    this.state.timerId = null;
    this.state.running = false;
    this.state.startedAt = null;
    this.state.index = this._findNext();
    this.state.remaining = this.tasks[this.state.index]?.duration ?? 0;
    if (this.state.index >= this.tasks.length) this.state.remaining = 0;
    this.onUpdate();
  }

  renderTimer(el) {
    const task = this.tasks[this.state.index];
    el.innerHTML = `
      <div class="timer-row">
        <div class="timer-state">${task ? task.title : '完了'}</div>
        <div class="timer-count">${task ? PlannerTimer.fmtSec(this.state.remaining) : '0:00'}</div>
      </div>
      <div class="buttons">
        <button class="primary" id="startBtn">${this.state.running ? '実行中' : '開始'}</button>
        <button class="secondary" id="pauseBtn">一時停止</button>
        <button class="secondary" id="nextBtn">次へ</button>
        <button class="secondary" id="resetBtn">最初から</button>
      </div>
    `;
    el.querySelector('#startBtn').disabled = this.state.running || this.state.index >= this.tasks.length;
    el.querySelector('#pauseBtn').disabled = !this.state.running;
    el.querySelector('#nextBtn').disabled = this.state.index >= this.tasks.length;
    el.querySelector('#startBtn').onclick = () => this.start();
    el.querySelector('#pauseBtn').onclick = () => this.pause();
    el.querySelector('#nextBtn').onclick = () => this.next();
    el.querySelector('#resetBtn').onclick = () => this.reset();
  }

  renderTasks(el) {
    el.innerHTML = '';
    this.tasks.forEach((task, i) => {
      const item = document.createElement('li');
      item.className = ['task', this.done[i] ? 'done' : i === this.state.index ? 'active' : ''].filter(Boolean).join(' ');
      item.innerHTML = `
        <input type="checkbox" ${this.done[i] ? 'checked' : ''} aria-label="${task.title}">
        <div class="task-main">
          <div class="task-title">${task.title}</div>
          <div class="task-duration">${PlannerTimer.fmtMin(task.duration)}</div>
        </div>
      `;
      const cb = item.querySelector('input');
      cb.addEventListener('change', () => this.toggle(i, cb.checked));
      item.addEventListener('click', e => {
        if (e.target.tagName !== 'INPUT') { cb.checked = !cb.checked; this.toggle(i, cb.checked); }
      });
      el.appendChild(item);
    });
  }
}
