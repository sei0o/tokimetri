import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  save() {
    const content = this.element.textContent.trim()
    const id = this.element.dataset.itemId
    fetch(`/planner_items/${id}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ planner_item: { content } })
    })
  }
}
