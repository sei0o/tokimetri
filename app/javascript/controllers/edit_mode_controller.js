import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle"]

  toggle() {
    const editing = this.element.classList.toggle("editing")
    this.toggleTargets.forEach(el => el.textContent = editing ? "完了" : "編集")
    this.element.querySelectorAll("li.task > span, li.note > div").forEach(el => {
      el.contentEditable = editing ? "true" : "false"
    })
    this.element.querySelectorAll("textarea").forEach(ta => {
      ta.readOnly = !editing
    })
  }
}
