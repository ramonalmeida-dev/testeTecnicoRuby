import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="filter-modal"
export default class extends Controller {
  static targets = ["form", "groupsContainer", "addGroupBtn"]
  
  connect() {
    console.log("Filter modal controller connected")
    // Inicializar com um grupo básico
    setTimeout(() => {
      this.addBasicGroup()
    }, 100)
  }

  addBasicGroup() {
    if (this.hasGroupsContainerTarget) {
      const template = document.getElementById('filterGroupTemplate')
      if (template) {
        const groupElement = template.content.cloneNode(true)
        this.groupsContainerTarget.appendChild(groupElement)
      }
    }
  }

  open() {
    this.element.style.display = 'flex'
    document.body.style.overflow = 'hidden'
  }

  close() {
    this.element.style.display = 'none'
    document.body.style.overflow = ''
  }

  addGroup() {
    const template = document.getElementById('filterGroupTemplate')
    if (template && this.hasGroupsContainerTarget) {
      const groupElement = template.content.cloneNode(true)
      this.groupsContainerTarget.appendChild(groupElement)
    }
  }

  clearFilters() {
    if (this.hasGroupsContainerTarget) {
      this.groupsContainerTarget.innerHTML = ''
      this.addBasicGroup()
    }
  }

  applyFilters() {
    // Por enquanto, apenas fechar o modal
    alert('Filtros aplicados! (Funcionalidade em desenvolvimento)')
    this.close()
  }
} 