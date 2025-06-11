import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "status", "textarea"]
  
  connect() {
    this.timeout = null
    this.setupAutoSave()
  }
  
  setupAutoSave() {
    const editor = this.element.querySelector("editor-text > textarea")
    
    if (editor) {
      // Listen for input events on the Trix editor
      editor.addEventListener("input", () => {
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
      this.statusTarget.textContent = "Saving..."
      
      this.formTarget.requestSubmit()

      this.statusTarget.textContent = "Saved"
    }
  }

  appendTime() {
    const s = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false })
    this.textareaTarget.value += s

    this.scheduleAutoSave()
  }
}
