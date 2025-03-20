import { Application } from "@hotwired/stimulus"
import CalendarController from "controllers/calendar_controller"

const application = Application.start()
application.register("calendar", CalendarController)

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
