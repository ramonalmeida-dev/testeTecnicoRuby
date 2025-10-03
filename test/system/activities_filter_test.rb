require "application_system_test_case"

class ActivitiesFilterTest < ApplicationSystemTestCase
  setup do
    @melhoria = activities(:melhoria_ativa)
    @bug = activities(:bug_ativo)
    @spike = activities(:spike_ativo)
  end

  test "should display all activities initially" do
    visit activities_url
    
    # Verificar se todas as atividades estão visíveis
    assert_text @melhoria.title
    assert_text @bug.title
    assert_text @spike.title
    
    # Verificar se o botão de filtro está presente
    assert_selector "button", text: "Filtrar"
  end

  test "should open filter modal when clicking filter button" do
    visit activities_url
    
    click_button "Filtrar"
    
    # Verificar se o modal abriu
    assert_selector ".filter-modal", visible: true
    assert_text "Filtrar indicador"
    
    # Verificar se os elementos do modal estão presentes
    assert_selector ".filter-field-select"
    assert_selector ".filter-value-input"
    assert_button "Aplicar filtro"
    assert_button "Limpar filtros"
  end

  test "should close filter modal when clicking close button" do
    visit activities_url
    
    click_button "Filtrar"
    assert_selector ".filter-modal", visible: true
    
    find(".filter-modal-close").click
    
    # Modal deve estar fechado
    assert_no_selector ".filter-modal", visible: true
  end

  test "should close filter modal when clicking backdrop" do
    visit activities_url
    
    click_button "Filtrar"
    assert_selector ".filter-modal", visible: true
    
    find(".filter-modal-backdrop").click
    
    # Modal deve estar fechado
    assert_no_selector ".filter-modal", visible: true
  end

  test "should populate field options in dropdown" do
    visit activities_url
    
    click_button "Filtrar"
    
    # Verificar se as opções de campo estão presentes
    within ".filter-field-select" do
      assert_text "Tipo"
      assert_text "Status" 
      assert_text "Urgência"
      assert_text "Responsável"
    end
  end

  test "should show value options when field is selected" do
    visit activities_url
    
    click_button "Filtrar"
    
    # Selecionar campo "Tipo"
    select "Tipo", from: find(".filter-field-select")
    
    # Aguardar o JavaScript atualizar o campo de valor
    sleep 0.5
    
    # Verificar se o campo de valor virou um select com opções
    value_select = find(".filter-value-input")
    
    # Se virou select, deve ter opções de tipo
    if value_select.tag_name == 'select'
      within value_select do
        assert_text "Melhoria"
        assert_text "Bug"
        assert_text "Spike"
      end
    end
  end

  test "should apply simple filter and update results" do
    visit activities_url
    
    # Contar atividades iniciais
    initial_count = all("table tbody tr").count
    
    click_button "Filtrar"
    
    # Configurar filtro para Bug (kind = 2)
    select "Tipo", from: find(".filter-field-select")
    
    # Aguardar JavaScript
    sleep 0.5
    
    # Se o campo de valor é um select, selecionar Bug
    value_input = find(".filter-value-input")
    if value_input.tag_name == 'select'
      select "Bug", from: value_input
    else
      fill_in value_input, with: "2"
    end
    
    click_button "Aplicar filtro"
    
    # Aguardar a atualização via AJAX
    sleep 1
    
    # Verificar se apenas atividades Bug são mostradas
    bug_activities = Activity.where(kind: 2)
    assert_equal bug_activities.count, all("table tbody tr").count
    
    # Verificar se o botão "Limpar filtros" apareceu
    assert_selector "button", text: "Limpar filtros"
  end

  test "should clear modal fields when clicking clear filters in modal" do
    visit activities_url
    
    click_button "Filtrar"
    
    # Configurar um filtro
    select "Tipo", from: find(".filter-field-select")
    sleep 0.5
    
    value_input = find(".filter-value-input")
    if value_input.tag_name == 'select'
      select "Bug", from: value_input
    else
      fill_in value_input, with: "2"
    end
    
    # Verificar se o campo foi preenchido
    if value_input.tag_name == 'select'
      assert_equal "2", value_input.value
    else
      assert_equal "2", value_input.value
    end
    
    # Limpar campos do modal (não deve aplicar na página)
    click_button "Limpar filtros"
    sleep 0.5
    
    # Verificar se os campos do modal foram limpos
    field_select = find(".filter-field-select")
    assert_equal "", field_select.value
    
    # Modal deve continuar aberto
    assert_selector ".filter-modal", visible: true
    
    # Fechar modal sem aplicar
    find(".filter-modal-close").click
    
    # Página deve continuar com todas as atividades (filtro não foi aplicado)
    assert_equal Activity.count, all("table tbody tr").count
  end

  test "should clear all filters from page button" do
    visit activities_url
    
    # Aplicar um filtro primeiro
    click_button "Filtrar"
    
    select "Tipo", from: find(".filter-field-select")
    sleep 0.5
    
    value_input = find(".filter-value-input")
    if value_input.tag_name == 'select'
      select "Bug", from: value_input
    else
      fill_in value_input, with: "2"
    end
    
    click_button "Aplicar filtro"
    sleep 1
    
    # Verificar se filtro foi aplicado e botão "Limpar filtros" apareceu
    assert_selector "button", text: "Limpar filtros"
    
    # Limpar filtros via botão da página
    click_button "Limpar filtros"
    
    # Aguardar limpeza
    sleep 1
    
    # Verificar se todas as atividades voltaram
    assert_equal Activity.count, all("table tbody tr").count
    
    # Verificar se o botão "Limpar filtros" sumiu
    assert_no_selector "button", text: "Limpar filtros"
  end

  test "should add multiple filters in same group" do
    visit activities_url
    
    click_button "Filtrar"
    
    # Primeiro filtro
    select "Tipo", from: find(".filter-field-select")
    sleep 0.5
    
    value_input = find(".filter-value-input")
    if value_input.tag_name == 'select'
      select "Bug", from: value_input
    else
      fill_in value_input, with: "2"
    end
    
    # Adicionar segundo filtro
    click_button "Adicionar filtro agrupado"
    
    # Configurar segundo filtro
    filter_rows = all(".filter-row")
    assert_equal 2, filter_rows.count
    
    within filter_rows.last do
      select "Status", from: find(".filter-field-select")
      sleep 0.5
      
      value_input = find(".filter-value-input")
      if value_input.tag_name == 'select'
        select "Ativo", from: value_input
      else
        fill_in value_input, with: "true"
      end
    end
    
    click_button "Aplicar filtro"
    sleep 1
    
    # Verificar se apenas atividades Bug E ativas são mostradas
    expected_count = Activity.where(kind: 2, status: true).count
    assert_equal expected_count, all("table tbody tr").count
  end

  test "should remove individual filters" do
    visit activities_url
    
    click_button "Filtrar"
    
    # Adicionar dois filtros
    select "Tipo", from: find(".filter-field-select")
    sleep 0.5
    
    click_button "Adicionar filtro agrupado"
    
    # Verificar que há 2 filtros
    assert_equal 2, all(".filter-row").count
    
    # Remover o primeiro filtro
    first(".btn-remove-filter").click
    
    # Verificar que agora há apenas 1 filtro
    assert_equal 1, all(".filter-row").count
  end

  test "should handle keyboard navigation" do
    visit activities_url
    
    click_button "Filtrar"
    
    # Testar navegação por Tab
    find(".filter-field-select").send_keys :tab
    
    # O foco deve estar no próximo elemento
    assert_equal find(".filter-value-input"), page.driver.browser.switch_to.active_element
  end

  test "should be responsive on mobile" do
    # Simular tela mobile
    page.driver.browser.manage.window.resize_to(375, 667)
    
    visit activities_url
    
    click_button "Filtrar"
    
    # Modal deve estar visível e responsivo
    assert_selector ".filter-modal", visible: true
    
    # Elementos devem estar empilhados verticalmente em mobile
    modal = find(".filter-modal-content")
    assert modal.native.size["width"] <= 400
  end

  test "should persist filters in URL" do
    visit activities_url
    
    click_button "Filtrar"
    
    select "Tipo", from: find(".filter-field-select")
    sleep 0.5
    
    value_input = find(".filter-value-input")
    if value_input.tag_name == 'select'
      select "Bug", from: value_input
    else
      fill_in value_input, with: "2"
    end
    
    click_button "Aplicar filtro"
    sleep 1
    
    # Verificar se a URL contém os filtros
    assert_match /filters=/, current_url
    
    # Recarregar a página
    visit current_url
    
    # Filtros devem persistir
    bug_activities = Activity.where(kind: 2)
    assert_equal bug_activities.count, all("table tbody tr").count
    assert_selector "button", text: "Limpar filtros"
  end
end 