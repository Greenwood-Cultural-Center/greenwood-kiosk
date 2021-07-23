# frozen_string_literal: true

# Base class for census record CRUD actions.
module CensusRecords
  class BaseController < ApplicationController
    include AdvancedRestoreSearch

    respond_to :json, only: :index
    respond_to :csv, only: :index
    respond_to :html

    before_action :check_access

    def index
      @page_title = page_title
      load_census_records
      render_census_records
    end

    def new
      authorize! :create, resource_class
      @record = resource_class.new
      @record.set_defaults
      @record.attributes = params.require(:attributes).permit! if params[:attributes]
    end

    def building_autocomplete
      record = resource_class.new street_house_number: params[:house],
                                  street_prefix: params[:prefix],
                                  street_name: params[:street],
                                  street_suffix: params[:suffix],
                                  city: params[:city]
      record.auto_strip_attributes
      buildings = BuildingsOnStreet.new(record).perform
      render json: buildings.to_json
    end

    def autocomplete
      results = AttributeAutocomplete.new(
        attribute: params[:attribute],
        term: params[:term],
        year: year
      ).perform
      render json: results
    end

    def create
      @record = resource_class.new resource_params
      authorize! :create, @record
      @record.created_by = current_user
      if @record.save
        flash[:notice] = 'Census Record created.'
        after_saved
      else
        flash[:errors] = 'Census Record not saved.'
        render action: :new
      end
    end

    def show
      @model = resource_class.find params[:id]
      authorize! :read, @model
      @record = CensusRecordPresenter.new @model, current_user
    end

    def edit
      @record = resource_class.find params[:id]
      authorize! :update, @record
    end

    def update
      @record = resource_class.find params[:id]
      authorize! :update, @record
      if @record.update(resource_params)
        flash[:notice] = 'Census Record updated.'
        after_saved
      else
        flash[:errors] = 'Census Record not saved.'
        render action: :edit
      end
    end

    def destroy
      @record = resource_class.find params[:id]
      authorize! :destroy, @record
      if @record.destroy
        flash[:notice] = 'Census Record deleted.'
        redirect_to action: :index
      else
        flash[:errors] = 'Unable to delete census record.'
        redirect_back fallback_location: { action: :index }
      end
    end

    def save_as
      @record = resource_class.find params[:id]
      authorize! :create, resource_class
      after_saved
    end

    def reviewed
      @record = resource_class.find params[:id]
      authorize! :review, @record
      @record.review! current_user
      flash[:notice] = 'The census record is marked as reviewed and available for public view.'
      redirect_back fallback_location: { action: :index }
    end

    def bulk_review
      authorize! :review, resource_class
      load_census_records

      @search.scoped.to_a.each do |record|
        next if record.reviewed?

        record.review! current_user
      end

      flash[:notice] = 'The census records are marked as reviewed and available for public view.'
      redirect_back fallback_location: { action: :index }
    end

    def make_person
      @record = resource_class.find params[:id]
      authorize! :create, resource_class
      @person = @record.generate_person_record
      @person.save
      flash[:notice] = 'A new person record has been created from this census record.'
      redirect_back fallback_location: { action: :index }
    end

    private

    # This is a blanket access check for whether this census year is activated for this HF instance
    def check_access
      permission_denied unless can_census?(year)
    end

    def page_title
      raise 'Need to implement page title.'
    end

    def resource_class
      raise 'resource_class needs a constant name!'
    end

    def resource_params
      params[:census_record].each do |key2, value|
        params[:census_record][key2] = nil if ['on', 'nil'].include?(value)
      end
      params.require(:census_record).permit!
    end

    def after_saved
      if params[:then].present?
        attributes = NextCensusRecordAttributes.new(@record, params[:then]).attributes
        redirect_to action: :new, attributes: attributes
      else
        redirect_to @record
      end
    end

    def load_census_records
      authorize! :read, resource_class
      @search = census_record_search_class.generate params: params, user: current_user, entity_class: resource_class, paged: request.format.html?, per: 100
    end

    def render_census_records
      respond_to do |format|
        format.html { render action: :index }
        format.csv { render_csv }
        format.json { render_json }
      end
    end

    def render_json
      if params[:from]
        render json: @search.row_data(@search.to_a)
      else
        respond_with @search.to_a, each_serializer: CensusRecordSerializer
      end
    end

    def render_csv
      headers['X-Accel-Buffering'] = 'no'
      headers['Cache-Control'] = 'no-cache'
      headers['Content-Type'] = 'text/csv; charset=utf-8'
      headers['Content-Disposition'] = "attachment; filename=\"historyforge-census-records-#{year}.csv\""
      headers['Last-Modified'] = Time.zone.now.ctime.to_s
      self.response_body = Enumerator.new do |csv|
        headers = @search.columns.map { |field| Translator.label(resource_class, field) }
        csv << CSV.generate_line(headers)
        @search.paged = false
        @search.to_a.each do |row|
          csv << CSV.generate_line(@search.columns.map { |field| row.field_for(field) })
        end
      end
    end

    # These are all defined in subclass but are declared here because of the helper_method call below
    def census_record_search_class; end

    def resource_path; end

    def new_resource_path; end

    def save_as_resource_path; end

    def edit_resource_path; end

    def reviewed_resource_path; end

    def collection_path; end

    def unhoused_collection_path; end

    def unreviewed_collection_path; end

    helper_method :resource_path,
                  :edit_resource_path,
                  :new_resource_path,
                  :save_as_resource_path,
                  :reviewed_resource_path,
                  :collection_path,
                  :unhoused_collection_path,
                  :unreviewed_collection_path,
                  :resource_class
  end
end