import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "summary", "total"]

  connect() {
    this.updateSummary()
  }

  toggle(event) {
    const checkbox = event.target
    const row = checkbox.closest("tr")
    
    if (checkbox.checked) {
      row.classList.add("selected")
    } else {
      row.classList.remove("selected")
    }
    
    this.updateSummary()
  }

  toggleRow(event) {
    // チェックボックス自体をクリックした場合は何もしない（toggleが呼ばれるため）
    if (event.target.type === 'checkbox') {
      return
    }
    
    const row = event.currentTarget
    const checkbox = row.querySelector('input[type="checkbox"]')
    
    if (checkbox) {
      checkbox.click() // calls toggle()
    }
  }

  reset() {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = false
      checkbox.closest("tr").classList.remove("selected")
    })
    this.updateSummary()
  }

  updateSummary() {
    const checkedCheckboxes = this.checkboxTargets.filter(cb => cb.checked)
    
    if (checkedCheckboxes.length === 0) {
      this.summaryTarget.style.display = "none"
      return
    }

    const totalMinutes = checkedCheckboxes.reduce((sum, checkbox) => {
      const duration = parseInt(checkbox.dataset.duration || 0)
      return sum + duration
    }, 0)

    const hours = Math.floor(totalMinutes / 60)
    const minutes = totalMinutes % 60
    const formattedTime = `${hours}:${minutes.toString().padStart(2, '0')}`

    this.totalTarget.textContent = formattedTime
    this.summaryTarget.style.display = "block"
  }
}
