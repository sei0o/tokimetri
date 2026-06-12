import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  save() {
    const listId = this.element.dataset.listId
    fetch(`/planner_lists/${listId}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ planner_list: { note: this.element.value } })
    })
  }
}
