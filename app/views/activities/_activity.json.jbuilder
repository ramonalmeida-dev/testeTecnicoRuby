json.extract! activity, :id, :title, :description, :status, :start_date, :end_date, :kind, :completed_percent, :priority, :urgency, :points, :created_at, :updated_at
json.url activity_url(activity, format: :json)
