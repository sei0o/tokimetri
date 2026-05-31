import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startTimeDisplay", "endTimeDisplay", "startTime", "endTime"]

  syncTime(event) {
    const display = event.target
    const isStart = display === this.startTimeDisplayTarget
    const hidden = isStart ? this.startTimeTarget : this.endTimeTarget

    const raw = display.value.trim()
    if (!raw) { hidden.value = ""; return }

    const match = raw.match(/^(-?\d+):(\d{2})$/)
    if (!match) return

    // 25時→翌日1時
    const totalHours = parseInt(match[1])
    const minutes = parseInt(match[2])
    const offsetDays = Math.floor(totalHours / 24)
    const hour = ((totalHours % 24) + 24) % 24

    const pageDate = new Date(display.closest("form").dataset.pageDate + "T00:00:00")
    pageDate.setDate(pageDate.getDate() + offsetDays)
    const dateStr = pageDate.toISOString().substring(0, 10)
    hidden.value = `${dateStr}T${String(hour).padStart(2, "0")}:${String(minutes).padStart(2, "0")}`
  }

  updateColor(event) {
    const option = event.target.options[event.target.selectedIndex]
    this.element.style.backgroundColor = option.dataset.color || ""
  }
}
