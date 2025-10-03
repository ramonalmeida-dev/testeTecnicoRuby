docker:
	sudo rm rails-app/tmp/pids/server.pid -f
	sudo docker-compose -f docker-compose.yml up --remove-orphans

bash:
	sudo docker-compose -f docker-compose.yml exec rails_app_teste /bin/bash
