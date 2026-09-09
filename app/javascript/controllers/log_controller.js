import { Controller } from "@hotwired/stimulus"

const toMinutes = (text) => {
  const m = text.match(/^(-?\d+):(\d{2})$/)
  return m ? parseInt(m[1]) * 60 + parseInt(m[2]) : null
}

const toHM = (minutes) => `${Math.floor(minutes / 60)}:${String(minutes % 60).padStart(2, "0")}`

export default class extends Controller {
  static targets = ["rows", "row", "activityTemplate", "noteTemplate"]

  connect() {
    this.index = Date.now()
    this.refresh()
  }

  // 開始時刻は前の行の終了時刻を引き継ぐ。placeholder で見せて、書けば上書きされる
  refresh() {
    let prevEnd = ""

    for (const row of this.rowTargets) {
      const start = row.querySelector(".start")
      const end = row.querySelector(".end")

      start.placeholder = prevEnd
      if (end?.value) prevEnd = end.value

      this.showDuration(row, start.value || start.placeholder, end?.value)
      row.querySelectorAll("textarea").forEach(this.grow)
    }

    const last = this.rowTargets.at(-1)
    if (last && this.filled(last)) this.addRow(this.activityTemplateTarget)
  }

  showDuration(row, from, to) {
    const cell = row.querySelector(".duration")
    if (!cell) return

    const start = toMinutes(from ?? "")
    const end = toMinutes(to ?? "")
    cell.textContent = start !== null && end !== null && end >= start ? toHM(end - start) : ""
  }

  filled(row) {
    return [...row.querySelectorAll("input[type=text], select, textarea")].some(el => el.value)
  }

  // メモは改行で伸びる
  grow(textarea) {
    textarea.style.height = "auto"
    textarea.style.height = `${textarea.scrollHeight}px`
  }

  addNote() {
    this.addRow(this.noteTemplateTarget)
  }

  addRow(template) {
    this.rowsTarget.insertAdjacentHTML("beforeend", template.innerHTML.replaceAll("NEW_RECORD", this.index++))
    this.refresh()
  }

  colorize(event) {
    event.target.closest("tr").style.backgroundColor = event.target.selectedOptions[0].dataset.color || ""
  }

  save(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === "s") {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }
}
