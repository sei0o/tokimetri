import { Controller } from "@hotwired/stimulus"

const toMinutes = (text) => {
  const m = text.match(/^(-?\d+):(\d{2})$/)
  return m ? parseInt(m[1]) * 60 + parseInt(m[2]) : null
}

const toHM = (minutes) => `${Math.floor(minutes / 60)}:${String(minutes % 60).padStart(2, "0")}`

export default class extends Controller {
  static targets = ["rows", "row", "activityTemplate", "noteTemplate"]
  static values = { date: String }

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
    this.rowsTarget.insertAdjacentHTML("beforeend", this.rowHTML(template))
    this.refresh()
  }

  rowHTML(template) {
    return template.innerHTML.replaceAll("NEW_RECORD", this.index++)
  }

  colorize(event) {
    event.target.closest("tr").style.backgroundColor = event.target.selectedOptions[0].dataset.color || ""
  }

  // 自分で選んだら推測の印を外す。input はプログラムからの代入では飛ばない
  accept(event) {
    event.target.classList.remove("guessed")
  }

  // 空いているカテゴリを過去の記録から埋める。外していたら選び直せばいい
  async guessCategory(event) {
    const select = event.target.closest("tr").querySelector("select")
    const what = event.target.value.trim()
    if (!select || select.value || !what) return

    const response = await fetch(`/category?what=${encodeURIComponent(what)}`)
    if (!response.ok) return

    const category = (await response.text()).trim()
    if (!category) return

    select.value = category
    if (select.value !== category) return

    select.classList.add("guessed")
    select.dispatchEvent(new Event("change", { bubbles: true }))
  }

  // いま終わったことにして次の行へ移る
  finishRow() {
    const current = this.rowTargets.findLast(row => this.filled(row))
    if (!current) return

    const end = current.querySelector(".end")
    if (end && !end.value) end.value = this.now()
    this.refresh()

    const next = this.rowTargets[this.rowTargets.indexOf(current) + 1]
    next?.querySelector('[name$="[what]"]')?.focus()
  }

  now() {
    const page = new Date(`${this.dateValue}T00:00:00`)
    const now = new Date()
    const midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    const days = Math.round((midnight - page) / 86400000)

    return `${days * 24 + now.getHours()}:${String(now.getMinutes()).padStart(2, "0")}`
  }

  key(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === "s") {
      event.preventDefault()
      this.element.requestSubmit()
      return
    }

    if (event.key !== "Enter") return

    // 日本語入力の変換確定の Enter は拾わない
    if (event.isComposing || event.keyCode === 229) return

    if (event.shiftKey) {
      event.preventDefault()
      this.insertBelow(event.target)
    } else if (event.target.tagName !== "TEXTAREA") {
      // メモの中では改行させる
      event.preventDefault()
      this.focusBelow(event.target)
    }
  }

  insertBelow(field) {
    const row = field.closest("tr")
    row.insertAdjacentHTML("afterend", this.rowHTML(this.activityTemplateTarget))
    this.refresh()
    this.focusBelow(field)
  }

  focusBelow(field) {
    const row = field.closest("tr")
    const next = this.rowTargets[this.rowTargets.indexOf(row) + 1]
    if (!next) return

    const column = field.name.match(/\[(\w+)\]$/)?.[1]
    const target = next.querySelector(`[name$="[${column}]"]`) ?? next.querySelector("input[type=text], textarea")
    target?.focus()
  }
}
