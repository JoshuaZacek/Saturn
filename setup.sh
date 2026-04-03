# frontend setup
printf "VUE_APP_API_URL=http://localhost:4000" > titan/.env.local

# backend setup
printf "CORS_URL=http://localhost:8080
PORT=4000
MIX_ENV=dev" > enceladus/.env

mkdir files

# fetch dependencies + compile backend and run migrations
cd enceladus
mix deps.get
mix deps.compile

mix ecto.create
mix ecto.migrate

# fetch dependencies for frontend
cd ../titan
npm install

echo "✅ \033[1;32mDevelopment environment for Saturn created\033[0m
Run \033[1;34miex -S mix\033[0m in \033[1;34m/enceladus\033[0m to start the backend.
Run \033[1;34mnpm run serve\033[0m in \033[1;34m/titan\033[0m to start the frontend."