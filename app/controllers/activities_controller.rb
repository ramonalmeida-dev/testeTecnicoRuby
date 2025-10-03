class ActivitiesController < ApplicationController
  before_action :set_activity, only: %i[ show edit update destroy ]

  # GET /activities or /activities.json
  def index
    activities_query = if filter_params.present?
                         Rails.logger.debug "Aplicando filtros: #{filter_params.inspect}"
                         begin
                           filtered_result = ActivityFilters::ActivityFilterService.call(filter_params)
                           Rails.logger.debug "Total de registros filtrados: #{filtered_result.count}"
                           filtered_result
                         rescue ActivityFilters::FilterError => e
                           Rails.logger.warn "Erro de filtro: #{e.message}"
                           flash.now[:alert] = "Erro nos filtros: #{e.message}"
                           Activity.all
                         end
                       else
                         Activity.all
                       end.includes(:user).order(:start_date)
    
    # Paginação simples - 20 itens por página
    page = params[:page].to_i
    page = 1 if page < 1
    per_page = 20
    offset = (page - 1) * per_page
    
    @activities = activities_query.limit(per_page).offset(offset)
    @total_count = activities_query.count
    @current_page = page
    @total_pages = (@total_count.to_f / per_page).ceil
    @per_page = per_page
    
    respond_to do |format|
      format.html
      format.json { render json: @activities }
    end
  end

  # GET /activities/1 or /activities/1.json
  def show
  end

  # GET /activities/new
  def new
    @activity = Activity.new
  end

  # GET /activities/1/edit
  def edit
  end

  # POST /activities or /activities.json
  def create
    @activity = Activity.new(activity_params)

    respond_to do |format|
      if @activity.save
        format.html { redirect_to @activity, notice: "Activity was successfully created." }
        format.json { render :show, status: :created, location: @activity }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /activities/1 or /activities/1.json
  def update
    respond_to do |format|
      if @activity.update(activity_params)
        format.html { redirect_to @activity, notice: "Activity was successfully updated." }
        format.json { render :show, status: :ok, location: @activity }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /activities/1 or /activities/1.json
  def destroy
    @activity.destroy!

    respond_to do |format|
      format.html { redirect_to activities_path, status: :see_other, notice: "Activity was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_activity
      @activity = Activity.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def activity_params
      params.expect(activity: [ :title, :description, :status, :start_date, :end_date, :kind, :completed_percent, :priority, :urgency, :points, :user_id ])
    end

    def filter_params
      return {} unless params[:filters].present?
      
      # Converte os parâmetros do frontend para o formato esperado pelo service
      filters = params[:filters]
      
      parsed_filters = if filters.is_a?(String)
        JSON.parse(filters).with_indifferent_access
      else
        filters.permit!.to_h.with_indifferent_access
      end
      
      # Validar e sanitizar os filtros
      sanitize_filter_params(parsed_filters)
    rescue JSON::ParserError => e
      Rails.logger.error "JSON Parse Error: #{e.message}"
      {}
    end

    def sanitize_filter_params(filters)
      return {} unless filters.is_a?(Hash) && filters[:groups].is_a?(Array)
      
      # Usar constantes do service para campos e operadores permitidos
      allowed_fields = ActivityFilters::ActivityFilterService::FILTERABLE_FIELDS.keys
      allowed_operators = ActivityFilters::ActivityFilterService::ALLOWED_OPERATORS
      
      sanitized_groups = filters[:groups].map do |group|
        next unless group.is_a?(Hash) && group[:filters].is_a?(Array)
        
        sanitized_filters = group[:filters].filter_map do |filter|
          next unless filter.is_a?(Hash)
          next unless allowed_fields.include?(filter[:field].to_s)
          next unless allowed_operators.include?(filter[:operator].to_s)
          
          {
            field: filter[:field].to_s,
            operator: filter[:operator].to_s,
            value: sanitize_filter_value(filter[:value]),
            operator_with_previous: filter[:operator_with_previous].to_s.upcase.in?(%w[AND OR]) ? filter[:operator_with_previous].to_s.upcase : 'AND'
          }
        end
        
        { operator: 'AND', filters: sanitized_filters } if sanitized_filters.any?
      end.compact
      
      {
        groups: sanitized_groups,
        group_operator: filters[:group_operator].to_s.upcase.in?(%w[AND OR]) ? filters[:group_operator].to_s.upcase : 'AND'
      }
    end

    def sanitize_filter_value(value)
      case value
      when String
        value.strip.truncate(255) # Limitar tamanho
      when Numeric
        value
      when TrueClass, FalseClass
        value
      else
        value.to_s.strip.truncate(255)
      end
    end
end
