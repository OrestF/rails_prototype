#!/usr/bin/env bash
# Verify a Rails app generated from the COAX rails_prototype template against the "green" definition in
# references/rails.md. Prints one PASS / FAIL / SKIP line per check and a summary.
#
# Usage: verify_rails.sh <app_dir> [base_url]
#   base_url   a running dev server to smoke-test, e.g. http://localhost:3000 (omit to skip the server checks)
#
# Environment:
#   RUBY_RUN   prefix for Ruby commands when the version manager is not loaded in this shell,
#              e.g. RUBY_RUN="$HOME/.rvm/bin/rvm 3.4.7 do"
#   SKIP       space-separated check names to skip, e.g. SKIP="brakeman production_eager_load"
#   PRODUCTION_DATABASE_URL
#              database the production eager load connects to (Search::Users reads the users schema at class
#              load). Default: the development database over TCP, postgres://$USER@localhost/<app>_development
#
# Exit status: 0 when every check that ran passed, 1 otherwise.
# Full output of each check: <app_dir>/tmp/setup-verify/<check>.log

set -u

app_dir=${1:?usage: verify_rails.sh <app_dir> [base_url]}
base_url=${2:-}
cd "$app_dir" || { echo "No such directory: $app_dir" >&2; exit 2; }

log_dir=tmp/setup-verify
mkdir -p "$log_dir"
failed=0
results=()

run() { ${RUBY_RUN:-} "$@"; }

check() {
  local name=$1
  shift
  if [[ " ${SKIP:-} " == *" $name "* ]]; then
    results+=("SKIP  $name")
    return
  fi
  echo "... $name"
  if "$@" >"$log_dir/$name.log" 2>&1; then
    results+=("PASS  $name")
  else
    results+=("FAIL  $name  (log: $app_dir/$log_dir/$name.log)")
    failed=1
    echo "--- $name failed, last lines:"
    tail -n 15 "$log_dir/$name.log"
  fi
}

# Boot + eager load: catches missing constants, class-load errors and initializer problems in every environment
check_dev_eager_load() { run bin/rails zeitwerk:check; }
check_test_eager_load() { CI=1 RAILS_ENV=test run bin/rails zeitwerk:check; }

# Production config + eager load, with credentials from ENV (as on a server). The app reads the users schema at
# class load, so it needs a reachable database; by default it borrows the development one (read-only introspection).
dev_database=$(sed -n 's/^ *database: *\([A-Za-z0-9_]*_development\) *$/\1/p' config/database.yml 2>/dev/null | head -n 1)
production_database_url=${PRODUCTION_DATABASE_URL:-${dev_database:+postgres://${USER}@localhost/$dev_database}}
check_production_eager_load() {
  RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 ADMIN_USERNAME=verify ADMIN_PASSWORD=verify \
    DEVISE_JWT_SECRET_KEY=verify DATABASE_URL=$production_database_url run bin/rails zeitwerk:check
}

check_specs() { run bundle exec rspec; }

# The CI test job (.github/workflows/docker_ci.yml) on the current working tree: a copy without credentials keys,
# credentials from ENV, CI=1 (eager load). Copying keeps the real keys in place even if the run is interrupted.
check_ci_specs() {
  local copy status
  copy=$(mktemp -d) || return 1
  rsync -a --exclude .git --exclude tmp --exclude log --exclude coverage --exclude node_modules \
    --exclude config/master.key --exclude 'config/credentials/*.key' ./ "$copy/" || { rm -rf "$copy"; return 1; }
  mkdir -p "$copy/tmp" "$copy/log"
  (
    cd "$copy" || exit 1
    export RAILS_ENV=test CI=1 ADMIN_USERNAME=admin ADMIN_PASSWORD=ci-test-password \
      DEVISE_JWT_SECRET_KEY=ci-test-only-jwt-secret
    run bin/rails db:test:prepare && run bundle exec rspec
  )
  status=$?
  rm -rf "$copy"
  return $status
}

check_rubocop() { run bundle exec rubocop; }
check_bundler_audit() { run bundle exec bundler-audit check --update; }

# Overcommit runs its hooks on the files in the git index; stage everything first for a full run
check_git_hooks() { run bundle exec overcommit --run; }

# Same exclusions as the template's .overcommit.yml Brakeman hook
check_brakeman() {
  run bundle exec brakeman --no-pager --quiet --exit-on-warn --except MassAssignment,PermitAttributes,SendFile
}

# Acceptance specs write the Apitome JSON and the OpenAPI (Swagger 2.0) file. Every run rewrites committed files
# with per-run values (tokens, Faker data, timestamps): report the churn so it is restored rather than committed.
check_api_docs() {
  run bundle exec rake docs:generate RAILS_ENV=test && test -s doc/api/index.json && test -s doc/api/open_api.json ||
    return 1
  local changed
  changed=$(git status --porcelain -- doc/api 2>/dev/null | wc -l | tr -d ' ')
  echo "doc/api files changed by this run: $changed"
  [ "$changed" = 0 ] || api_docs_note="NOTE  api_docs rewrote $changed files in doc/api; if no spec changed, restore them: git checkout -- doc/api"
}
api_docs_note=""

check_smoke_endpoints() {
  local path code bad=0
  for path in /up / /api/docs /open_api_docs /jobs /maintenance_tasks /motor_admin; do
    code=$(curl -s -o /dev/null -w '%{http_code}' "$base_url$path")
    echo "GET $path -> $code"
    [ "$code" = 200 ] || bad=1
  done
  return $bad
}

# Sign in -> profile -> sign out -> revoked token, with a throwaway user that is removed afterwards
check_smoke_auth() {
  local email="setup-verify-$$@example.com" password="Verify-$$-Passw0rd" headers token bad=0
  local profile=(-H 'Accept: application/json')
  run bin/rails runner "User.create!(email: '$email', password: '$password')" || return 1

  headers=$(mktemp)
  code=$(curl -s -D "$headers" -o /dev/null -w '%{http_code}' -X POST "$base_url/api/v1/users/sign_in" \
    -H 'Content-Type: application/json' -H 'Accept: application/json' \
    -d "{\"user\":{\"email\":\"$email\",\"password\":\"$password\"}}")
  token=$(grep -i '^authorization:' "$headers" | cut -d' ' -f2- | tr -d '\r')
  rm -f "$headers"
  echo "POST sign_in -> $code (token: $([ -n "$token" ] && echo present || echo missing))"
  [ "$code" = 200 ] && [ -n "$token" ] || bad=1

  code=$(curl -s -o /dev/null -w '%{http_code}' "${profile[@]}" -H "Authorization: $token" "$base_url/api/v1/users/profile")
  echo "GET profile with token -> $code"
  [ "$code" = 200 ] || bad=1

  code=$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "${profile[@]}" -H "Authorization: $token" "$base_url/api/v1/users/sign_out")
  echo "DELETE sign_out -> $code"
  [ "$code" = 204 ] || bad=1

  code=$(curl -s -o /dev/null -w '%{http_code}' "${profile[@]}" -H "Authorization: $token" "$base_url/api/v1/users/profile")
  echo "GET profile with revoked token -> $code"
  [ "$code" = 401 ] || bad=1

  run bin/rails runner "User.find_by(email: '$email')&.destroy" >/dev/null 2>&1
  return $bad
}

check dev_eager_load check_dev_eager_load
check test_eager_load check_test_eager_load
if [ -n "$production_database_url" ]; then
  check production_eager_load check_production_eager_load
else
  results+=("SKIP  production_eager_load (no development database found; set PRODUCTION_DATABASE_URL)")
fi
check specs check_specs
check ci_specs check_ci_specs
check rubocop check_rubocop
check brakeman check_brakeman
check bundler_audit check_bundler_audit
if [ -f .git/hooks/overcommit-hook ]; then
  check git_hooks check_git_hooks
else
  results+=("SKIP  git_hooks (Overcommit not installed yet)")
fi
check api_docs check_api_docs
if [ -n "$base_url" ]; then
  check smoke_endpoints check_smoke_endpoints
  check smoke_auth check_smoke_auth
else
  results+=("SKIP  smoke_endpoints, smoke_auth (no base_url given)")
fi

echo
echo "== Verification summary ($(date '+%Y-%m-%d %H:%M'))"
printf '%s\n' "${results[@]}"
[ -z "$api_docs_note" ] || echo "$api_docs_note"
exit $failed
