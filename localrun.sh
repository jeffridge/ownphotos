#! /bin/bash

export MAPBOX_API_KEY=pk.eyJ1IjoiamVmZnJpZGdlIiwiYSI6ImNqbXFrbW5pODFxeDcza2pwbnY2Z3E2NWUifQ.ZSaaf3cpnV-XOo1nfxyJsQ
export ALLOWED_HOSTS=*
export ADMIN_EMAIL=jeff@laughlinzoo.com
export ADMIN_USERNAME=admin
export ADMIN_PASSWORD=forumpass
export SECRET_KEY=Z5BbX8xhnY9xBjvD
export DEBUG=true
export DB_BACKEND=postgresql
export DB_NAME=ownphotos
export DB_USER=postgres
export DB_PASS=Z5BbX8xhnY9xBjvD
export DB_HOST=ownphotos.laughlinzoo.com
export DB_PORT=5432
export BACKEND_HOST=ownphotos-dev.laughlinzoo.com
export BACKEND_PROTOCOL=http
export REDIS_HOST=ownphotos.laughlinzoo.com
export REDIS_PORT=6379
export TIME_ZONE=UTC


cp /code/nginx.conf /etc/nginx/sites-enabled/default
BACKEND_URL=${BACKEND_PROTOCOL}${BACKEND_HOST}
sed -i -e 's/replaceme/'"$BACKEND_HOST"'/g' /etc/nginx/sites-enabled/default
service nginx restart

source /venv/bin/activate

python manage.py migrate
python manage.py migrate --run-syncdb

python manage.py shell <<EOF
from django.contrib.auth.models import User
User.objects.filter(email='$ADMIN_EMAIL').delete()
User.objects.create_superuser('$ADMIN_USERNAME', '$ADMIN_EMAIL', '$ADMIN_PASSWORD')
EOF

echo "Running backend server..."

python manage.py rqworker default &
gunicorn --bind 0.0.0.0:8001 ownphotos.wsgi &



sed -i -e 's/http:\/\/changeme/'"$BACKEND_URL"'/g' /code/ownphotos-frontend/src/api_client/apiClient.js
cd /code/ownphotos-frontend
npm run build
serve -s build
