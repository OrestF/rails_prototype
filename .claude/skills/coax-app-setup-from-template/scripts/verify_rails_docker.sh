#!/usr/bin/env bash
# Verify the Docker setup of a Rails app generated from the COAX rails_prototype template against the "green"
# definition in references/rails.md ("CI and Docker"). Prints one PASS / FAIL / SKIP line per check and a summary.
#
# Usage: verify_rails_docker.sh <app_dir>
#
#   1. The CI test job, as .github/workflows/docker_ci.yml runs it: Compose profile "cicd", the specs through
#      docker-entrypoint.test.sh, under its own project name, whose volumes are removed afterwards.
#   2. The development stack, Compose profile "development": build, start, then checks against the containers.
#      It is left running; stop it with: docker compose --env-file stack.env --profile development down
#
# Environment:
#   DOCKER_BIN   docker CLI to use. Default: the first working one of `docker` on PATH and the CLIs bundled with
#                Docker Desktop and OrbStack (a symlink left behind by another runtime can dangle)
#   RAILS_PUBLISHED_PORT, POSTGRES_PUBLISHED_PORT
#                host ports of the development stack. Default: the value in stack.env, else 3000 / 5432, or
#                3001 / 5433 when a local Rails server or PostgreSQL already listens there
#   SKIP         space-separated check names to skip, e.g. SKIP="ci_specs"
#
# stack.env (gitignored) configures the development stack; when it is missing it is created from .env.test with
# RAILS_ENV=development. The CI run swaps in .env.test, as CI does, and restores stack.env afterwards.
#
# Exit status: 0 when every check that ran passed, 1 otherwise.
# Full output of each check: <app_dir>/tmp/setup-verify/docker_<check>.log

set -u

app_dir=${1:?usage: verify_rails_docker.sh <app_dir>}
cd "$app_dir" || { echo "No such directory: $app_dir" >&2; exit 2; }

log_dir=tmp/setup-verify
mkdir -p "$log_dir"
failed=0
results=()

check() {
  local name=$1
  shift
  if [[ " ${SKIP:-} " == *" $name "* ]]; then
    results+=("SKIP  $name")
    return 0
  fi
  echo "... $name"
  if "$@" >"$log_dir/docker_$name.log" 2>&1; then
    results+=("PASS  $name")
  else
    results+=("FAIL  $name  (log: $app_dir/$log_dir/docker_$name.log)")
    failed=1
    echo "--- $name failed, last lines:"
    tail -n 15 "$log_dir/docker_$name.log"
    return 1
  fi
}

skip_rest() {
  local name
  for name in "$@"; do results+=("SKIP  $name ($skip_reason)"); done
}

find_docker() {
  local candidate
  for candidate in ${DOCKER_BIN:-} "$(command -v docker 2>/dev/null)" \
    /Applications/Docker.app/Contents/Resources/bin/docker "$HOME/.orbstack/bin/docker" \
    /opt/homebrew/bin/docker /usr/local/bin/docker; do
    if [ -n "$candidate" ] && [ -x "$candidate" ] &&
      "$candidate" version --format '{{.Client.Version}}' >/dev/null 2>&1; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

docker_bin=$(find_docker) || { echo "No working docker CLI found; set DOCKER_BIN" >&2; exit 2; }
# Credential helpers (docker-credential-desktop) live next to the CLI and must be on PATH for pulls
PATH="$(dirname "$docker_bin"):$PATH"

compose() { docker compose --env-file stack.env "$@"; }
dev() { compose --profile development "$@"; }
rails_runner() { dev exec -T rails bundle exec rails runner "$@"; }

app_name=$(sed -n 's/^APP_NAME=//p' .env.test 2>/dev/null | head -n 1)
ci_project="${app_name:-app}_verify_ci"

# --- ports: never fight a local PostgreSQL or Rails server for 5432 / 3000 ---
port_taken() { lsof -nP -i :"$1" -sTCP:LISTEN >/dev/null 2>&1; }
stack_env_value() { sed -n "s/^$1=//p" stack.env 2>/dev/null | tail -n 1; }
pick_port() {
  local name=$1 preferred=$2 fallback=$3 configured
  configured=${!name:-$(stack_env_value "$name")}
  if [ -n "$configured" ]; then
    echo "$configured"
  elif port_taken "$preferred"; then
    echo "$fallback"
  else
    echo "$preferred"
  fi
}

# --- stack.env is swapped for the CI run; restore it whatever happens ---
stack_env_backup=""
restore_stack_env() {
  [ -n "$stack_env_backup" ] || return 0
  cp "$stack_env_backup" stack.env && rm -f "$stack_env_backup"
  stack_env_backup=""
}
trap restore_stack_env EXIT

check_docker_daemon() {
  echo "CLI: $docker_bin"
  docker version --format 'client {{.Client.Version}}, server {{.Server.Version}} ({{.Server.Arch}})'
  docker compose version
}

check_compose_config() { dev config -q && compose --profile cicd config -q; }

# The bind mount (.:/var/www) hides the image's chmod, and CI checks the files out with their git mode
check_entrypoints() {
  local file mode bad=0
  for file in docker-entrypoint*.sh; do
    mode=$(git ls-files -s -- "$file" 2>/dev/null | cut -c1-6)
    echo "$file: disk $([ -x "$file" ] && echo executable || echo NOT executable), git ${mode:-untracked}"
    [ -x "$file" ] || bad=1
    [ -z "$mode" ] || [ "$mode" = 100755 ] || bad=1
  done
  return $bad
}

# The template's workflow is filled in for this app: the same APP_NAME as .env.test, and its Compose project
check_ci_workflow() {
  local workflow=.github/workflows/docker_ci.yml workflow_app bad=0
  [ -f "$workflow" ] || { echo "$workflow is missing"; return 1; }
  if grep -n '<app_name>' "$workflow"; then
    echo "placeholder <app_name> left in $workflow"
    bad=1
  fi
  workflow_app=$(sed -n 's/^  APP_NAME: *"\{0,1\}\([A-Za-z0-9_-]*\)"\{0,1\}.*/\1/p' "$workflow" | head -n 1)
  echo "APP_NAME: workflow ${workflow_app:-none}, .env.test ${app_name:-none}"
  [ -n "$workflow_app" ] && [ "$workflow_app" = "$app_name" ] || bad=1
  if ! grep -q "COMPOSE_PROJECT_NAME: \"${app_name}_" "$workflow"; then
    echo "COMPOSE_PROJECT_NAME does not start with ${app_name}_"
    bad=1
  fi
  if [ -f .github/workflows/ci.yml ]; then
    echo ".github/workflows/ci.yml (the generator's workflow, no specs) is still there"
    bad=1
  fi
  return $bad
}

check_ci_specs() {
  local status examples started="$log_dir/docker_ci_specs.started"
  stack_env_backup=$(mktemp) && cp stack.env "$stack_env_backup" && cp .env.test stack.env || return 1
  touch "$started"
  ci() { compose --project-name "$ci_project" "$@"; }
  ci --profile=cicd up -d &&
    ci build rails --build-arg RAILS_ENV=test &&
    ci run --rm --entrypoint=./docker-entrypoint.test.sh --env RAILS_ENV=test \
      --env ADMIN_USERNAME=admin --env ADMIN_PASSWORD=ci-test-password \
      --env DEVISE_JWT_SECRET_KEY=ci-test-only-jwt-secret --env APP_ROOT="$PWD" rails
  status=$?
  ci --profile=cicd down --volumes
  restore_stack_env
  [ "$status" = 0 ] || return "$status"
  examples=$(grep -aoE '[0-9]+ examples?, 0 failures' "$log_dir/docker_ci_specs.log" | tail -n 1 | cut -d' ' -f1)
  echo "examples run: ${examples:-none}"
  [ "${examples:-0}" -gt 0 ] || { echo "The CI test job ran no examples"; return 1; }
  [ coverage/coverage.json -nt "$started" ] || { echo "coverage/coverage.json was not written by this run"; return 1; }
}

check_dev_stack() {
  local code="" attempt container state expected running bad=0
  dev build rails && dev up -d || return 1
  for attempt in $(seq 1 90); do
    code=$(curl -s -o /dev/null -w '%{http_code}' "$base_url/up")
    [ "$code" = 200 ] && break
    sleep 2
  done
  echo "GET $base_url/up -> $code"
  [ "$code" = 200 ] || return 1
  sleep 20 # long enough for a crash-looping service (jobs) to show restarts
  expected=$(dev config --services | wc -l | tr -d ' ')
  running=0
  for container in $(dev ps -a -q); do
    state=$(docker inspect -f '{{.Name}} {{.State.Status}} restarts={{.RestartCount}}' "$container")
    echo "$state"
    case "$state" in
      *" running restarts=0") running=$((running + 1)) ;;
      *) bad=1 ;;
    esac
  done
  echo "services running: $running of $expected"
  [ "$running" = "$expected" ] || bad=1
  return $bad
}

check_smoke_endpoints() {
  local path code bad=0
  for path in /up / /api/docs /open_api_docs /jobs /maintenance_tasks /motor_admin; do
    code=$(curl -s -o /dev/null -w '%{http_code}' "$base_url$path")
    echo "GET $path -> $code"
    [ "$code" = 200 ] || bad=1
  done
  return $bad
}

# Sign in -> profile -> sign out -> revoked token, with a throwaway user created inside the container
check_smoke_auth() {
  local email="docker-verify-$$@example.com" password="Verify-$$-Passw0rd" headers token code bad=0
  local accept=(-H 'Accept: application/json')
  rails_runner "User.create!(email: '$email', password: '$password')" || return 1

  headers=$(mktemp)
  code=$(curl -s -D "$headers" -o /dev/null -w '%{http_code}' -X POST "$base_url/api/v1/users/sign_in" \
    -H 'Content-Type: application/json' "${accept[@]}" \
    -d "{\"user\":{\"email\":\"$email\",\"password\":\"$password\"}}")
  token=$(grep -i '^authorization:' "$headers" | cut -d' ' -f2- | tr -d '\r')
  rm -f "$headers"
  echo "POST sign_in -> $code (token: $([ -n "$token" ] && echo present || echo missing))"
  [ "$code" = 200 ] && [ -n "$token" ] || bad=1

  code=$(curl -s -o /dev/null -w '%{http_code}' "${accept[@]}" -H "Authorization: $token" "$base_url/api/v1/users/profile")
  echo "GET profile with token -> $code"
  [ "$code" = 200 ] || bad=1

  code=$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "${accept[@]}" -H "Authorization: $token" "$base_url/api/v1/users/sign_out")
  echo "DELETE sign_out -> $code"
  [ "$code" = 204 ] || bad=1

  code=$(curl -s -o /dev/null -w '%{http_code}' "${accept[@]}" -H "Authorization: $token" "$base_url/api/v1/users/profile")
  echo "GET profile with revoked token -> $code"
  [ "$code" = 401 ] || bad=1

  rails_runner "User.find_by(email: '$email')&.destroy"
  return $bad
}

# The jobs service registered a Solid Queue worker that is still sending heartbeats
check_jobs() {
  rails_runner 'workers = SolidQueue::Process.where(kind: "Worker").where("last_heartbeat_at > ?", 1.minute.ago)
    puts "live Solid Queue workers: #{workers.count}"
    exit(workers.exists? ? 0 : 1)'
}

# Active Storage writes to the named volume, not into the bind-mounted host directory
check_storage() {
  dev exec -T rails grep ' /var/www/storage ' /proc/mounts || { echo "/var/www/storage is not a volume"; return 1; }
  rails_runner 'blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("probe"), filename: "probe.txt")
    path = ActiveStorage::Blob.service.path_for(blob.key)
    stored = File.exist?(path)
    blob.purge
    puts "uploaded to #{path}: #{stored}"
    exit(stored ? 0 : 1)'
}

# Precompiled assets in the bind-mounted public/assets make both the container and a local server ignore changes
check_host_assets() {
  if [ -e public/assets/.manifest.json ]; then
    echo "public/assets/.manifest.json exists: something precompiled assets in development"
    return 1
  fi
  echo "no precompiled assets in public/assets"
}

# --- run ---
if ! check docker_daemon check_docker_daemon; then
  skip_reason="Docker daemon not reachable"
  skip_rest compose_config entrypoints ci_workflow ci_specs dev_stack smoke_endpoints smoke_auth jobs storage host_assets
else
  if [ ! -f stack.env ]; then
    sed 's/^RAILS_ENV=.*/RAILS_ENV=development/' .env.test > stack.env
    echo "Created stack.env from .env.test with RAILS_ENV=development"
  fi
  check compose_config check_compose_config
  check entrypoints check_entrypoints
  check ci_workflow check_ci_workflow
  # Both stacks use the same fixed container names, so the development stack goes down first (volumes are kept)
  dev down >/dev/null 2>&1
  RAILS_PUBLISHED_PORT=$(pick_port RAILS_PUBLISHED_PORT 3000 3001)
  POSTGRES_PUBLISHED_PORT=$(pick_port POSTGRES_PUBLISHED_PORT 5432 5433)
  export RAILS_PUBLISHED_PORT POSTGRES_PUBLISHED_PORT
  base_url="http://localhost:$RAILS_PUBLISHED_PORT"
  echo "Development stack ports: rails $RAILS_PUBLISHED_PORT, postgres $POSTGRES_PUBLISHED_PORT"
  check ci_specs check_ci_specs
  if check dev_stack check_dev_stack; then
    check smoke_endpoints check_smoke_endpoints
    check smoke_auth check_smoke_auth
    check jobs check_jobs
    check storage check_storage
  else
    skip_reason="development stack not healthy"
    skip_rest smoke_endpoints smoke_auth jobs storage
  fi
  check host_assets check_host_assets
fi

echo
echo "== Docker verification summary ($(date '+%Y-%m-%d %H:%M'))"
printf '%s\n' "${results[@]}"
if [ -n "${base_url:-}" ]; then
  echo "Development stack: $base_url (stop: docker compose --env-file stack.env --profile development down)"
fi
exit $failed
