import { Controller } from "@hotwired/stimulus"

const request = (url, method, body) => fetch(url, {
  method,
  body,
  headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content }
})

// ページを読み直すと log の書きかけが消えるので、ここは全部 fetch で済ませる
export default class extends Controller {
  static targets = ["today"]
  static values = { date: String }

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
  }

  async done({ params: { id }, target }) {
    const response = await request(`/tasks/${id}`, "DELETE")
    if (response.ok) target.closest("tr").remove()
  }

  async today({ params: { id }, target }) {
    const body = new FormData()
    body.append("to", "today")

    const response = await request(`/tasks/${id}`, "PATCH", body)
    if (!response.ok) return

    const row = target.closest("tr")
    target.remove()
    this.todayTarget.append(row)
  }

  // log に行を始めてもらう。タスクなら plan からは消える
  start({ params: { id, what, category }, target }) {
    this.dispatch("start", { detail: { what, category } })
    target.closest("tr").querySelector("details")?.setAttribute("open", "")
    if (id) this.done({ params: { id }, target })
  }
}
