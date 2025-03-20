import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "status"]
  
  connect() {
    this.timeout = null
    this.setupAutoSave()
  }
  
  setupAutoSave() {
    // Get the Trix editor element
    const trixEditor = this.element.querySelector("trix-editor")
    
    if (trixEditor) {
      // Listen for input events on the Trix editor
      trixEditor.addEventListener("trix-change", () => {
        this.scheduleAutoSave()
      })
    }
  }
  
  scheduleAutoSave() {
    // Clear any existing timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    
    // Set status to "Editing..."
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "Editing..."
    }
    
    // Set a new timeout for 3 seconds
    this.timeout = setTimeout(() => {
      this.autoSave()
    }, 2000)
  }
  
  autoSave() {
    if (this.hasFormTarget) {
      // Set status to "Saving..."
      if (this.hasStatusTarget) {
        this.statusTarget.textContent = "Saving..."
      }
      
      // Submit the form using Turbo
      this.formTarget.requestSubmit()
    }
  }
}
