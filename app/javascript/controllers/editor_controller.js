import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "status", "textarea"]
  
  connect() {
    this.timeout = null
    this.setupAutoSave()
    console.log(this)

    this.textareaTarget.addEventListener("keydown", this.handleTab);
  }

  disconnect() {
    this.textareaTarget.removeEventListener("keydown", this.handleTab);
  }

  handleTab(e) {
    if (e.key === "Tab") {
      e.preventDefault();
      const start = this.selectionStart;
      const end = this.selectionEnd;
      const value = this.value;

      if (e.shiftKey) {
        // Unindent: remove up to 2 spaces before the cursor
        const before = value.substring(0, start);
        const after = value.substring(end);
        const unindentedBefore = before.replace(/ {1,2}$/, "");
        const removed = before.length - unindentedBefore.length;
        this.value = unindentedBefore + after;
        this.selectionStart = this.selectionEnd = start - removed;
      } else {
        // Indent: insert 2 spaces at the cursor
        this.value = value.substring(0, start) + "  " + value.substring(end);
        this.selectionStart = this.selectionEnd = start + 2;
      }
    }
  };  

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
