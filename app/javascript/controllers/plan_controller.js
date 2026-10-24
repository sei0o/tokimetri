import { Controller } from "@hotwired/stimulus"
import { durationToMinutes, toHM } from "minutes"

const request = (url, method, body) => fetch(url, {
  method,
  body,
  headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content }
})

// ページを読み直すと log の書きかけが消えるので、ここは全部 fetch で済ませる
export default class extends Controller {
  static targets = ["today", "total", "free"]
  static values = { date: String, left: Number }

  async add(event) {
    if (event.isComposing || event.keyCode === 229) return
    event.preventDefault()

    const input = event.target
    const content = input.value.trim()
    if (!content) return

    const body = new FormData()
    body.append("task[content]", content)
    body.append("task[date]", this.dateValue)

    const response = await request("/tasks", "POST", body)
    if (!response.ok) return

    this.todayTarget.insertAdjacentHTML("beforeend", await response.text())
    input.value = ""
    this.refreshTotal()
  }

  async done({ params: { id }, target }) {
    const response = await request(`/tasks/${id}`, "DELETE")
    if (!response.ok) return

    target.closest("tr").remove()
    this.refreshTotal()
  }

  async today({ params: { id }, target }) {
    const body = new FormData()
    body.append("to", "today")

    const response = await request(`/tasks/${id}`, "PATCH", body)
    if (!response.ok) return

    const row = target.closest("tr")
    target.remove()
    this.todayTarget.append(row)
    this.refreshTotal()
  }

  // 行の欄を書き換えたらその場で保存する
  async save({ target }) {
    const row = target.closest("tr")
    const estimate = row.querySelector("[name='task[estimate_minutes]']")
    const minutes = durationToMinutes(estimate.value)
    if (minutes !== null) estimate.value = toHM(minutes)

    const body = new FormData()
    row.querySelectorAll("[name^='task[']").forEach(field => body.append(field.name, field.value))

    await request(`/tasks/${row.dataset.id}`, "PATCH", body)
    this.refreshTotal()
  }

  refreshTotal() {
    const minutes = [...this.todayTarget.rows]
      .reduce((sum, row) => sum + (durationToMinutes(row.querySelector("[name='task[estimate_minutes]']").value) ?? 0), 0)
    this.totalTarget.textContent = toHM(minutes)
    if (this.hasFreeTarget) this.freeTarget.textContent = toHM(this.leftValue - minutes)
  }

  // log に行を始めてもらう。タスクなら plan からは消える
  start({ params: { id, what, category }, target }) {
    const row = target.closest("tr")
    if (id) {
      what = row.querySelector("[name='task[content]']").value
      category = row.querySelector("[name='task[category]']").value
    }
    this.dispatch("start", { detail: { what, category, project: row.dataset.project } })
    row.querySelector("details")?.setAttribute("open", "")
    if (id) this.done({ params: { id }, target })
  }
}
