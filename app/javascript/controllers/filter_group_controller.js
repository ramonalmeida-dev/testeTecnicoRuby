import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="filter-group"
export default class extends Controller {
  static targets = ["groupOperator", "filtersContainer", "addFilterBtn"]
  
  connect() {
    console.log("Filter group controller connected")
    // Adicionar um filtro inicial
    setTimeout(() => {
      this.addFilter()
    }, 100)
  }

  addFilter() {
    const template = document.getElementById('filterTemplate')
    if (template && this.hasFiltersContainerTarget) {
      const filterElement = template.content.cloneNode(true)
      this.filtersContainerTarget.appendChild(filterElement)
    }
  }

  removeFilter(event) {
    const filterRow = event.target.closest('.filter-row')
    if (filterRow) {
      filterRow.remove()
    }
    
    // Se não há mais filtros, adicionar um novo
    if (this.hasFiltersContainerTarget && this.filtersContainerTarget.children.length === 0) {
      this.addFilter()
    }
  }

  updateField(event) {
    console.log("Field updated:", event.target.value)
    // Lógica para atualizar operadores baseado no campo selecionado
  }

  updateOperator(event) {
    console.log("Operator updated:", event.target.value)
    // Lógica para atualizar input de valor baseado no operador
  }

  updateGroupOperator(event) {
    console.log("Group operator updated:", event.target.value)
  }

  updateFilterOperator(event) {
    console.log("Filter operator updated:", event.target.value)
  }
} 