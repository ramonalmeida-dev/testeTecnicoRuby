import { Application } from "@hotwired/stimulus"
import FilterModalController from "./filter_modal_controller"
import FilterGroupController from "./filter_group_controller"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

// Register controllers
application.register("filter-modal", FilterModalController)
application.register("filter-group", FilterGroupController)

export { application } 