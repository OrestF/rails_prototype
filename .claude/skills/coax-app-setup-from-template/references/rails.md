# Ruby on Rails (API): COAX rails_prototype template

AI config tier for step 1: `ruby`.

## Contents

1. Template source
2. What the template provides (for honest checklist ticking)
3. Prerequisites
4. Generate
5. Configure
6. Verify: the definition of green
7. Run the server
8. Remaining checklist items
9. Known failures

## 1. Template source

The template is `template.rb` in [OrestF/rails_prototype](https://github.com/OrestF/rails_prototype), branch
`main`. At generation time it downloads about 90 more files (controllers, ABDI layers, specs, configs, Docker
files) from the same branch, so `template.rb` and its files always come from one place.

| Source | When | Flag |
| --- | --- | --- |
| GitHub `main` (default) | Every setup, unless the user explicitly asks otherwise | `--template=https://raw.githubusercontent.com/OrestF/rails_prototype/main/template.rb` |
| Local checkout | Only when the user explicitly asks for it (unmerged template changes) | `DEV_MODE=true` env plus `--template=<checkout>/template.rb`; files are copied from the checkout |

The Wiki's Project setup page links [railsbytes Xo5s6a](https://railsbytes.com/templates/Xo5s6a). That is an
older revision of this template: Redis, sweet_staging, Sprockets and rspec-rails 4. Do not use it unless the
competence lead asks for it, and mention that the Wiki link is stale. With a local checkout, note its branch and commit
in the checklist header so it is clear exactly what was used. A local checkout also copies
untracked files, so a run that works in `DEV_MODE` can still 404 from GitHub: commit every file `template.rb`
downloads before merging template changes to `main`.

## 2. What the template provides

- Rails API on PostgreSQL with Propshaft, Solid Queue (also in development, with its own queue database), Solid
  Cache and Solid Cable
- Devise + JWT (+ invitable, lockable), Pundit + Passpartu, and the ABDI layers in `data/`, `business/` and
  `infrastructure/`
- RSpec with acceptance specs; rspec_api_documentation writes the Apitome docs and the OpenAPI file
  (`doc/api/open_api.json`)
- RuboCop (rails-omakase plus house config), Brakeman, bundler-audit, fasterer, and an Overcommit config
  (`.overcommit.yml`; hooks are not installed)
- Motor Admin, maintenance_tasks, Mission Control Jobs, and a development home page
- `README.md` and `CHANGELOG.md` copied from generic examples (not project content)
- Docker: a Dockerfile on the generator's Ruby, Compose with `postgres`, `rails` and `jobs` (profiles
  `development` and `cicd`), executable entrypoints, a committed `.env.test`, and `database.yml` reading
  `POSTGRES_*`
- CI: `.github/workflows/docker_ci.yml` (doer_be_api pattern: linters on the runner, specs in Docker Compose,
  SonarQube with coverage) with the app name filled in, instead of the generator's `ci.yml`
- Template revisions before the Docker and CI update lack the last two: "CI and Docker" (section 8) lists what to
  check
- Leftovers to know about:
  - `.env.example` is copied only to the gitignored `.env`, so no example env file is committed.
  - `.kamal/secrets` holds a random value even with `--skip-kamal`; nothing uses it, so delete it.
  - `lemme_check_remote.sh` pipes a remote script into Ruby; it is a template utility, not project code.
  - `.github/dependabot.yml` comes from the generator.
  - Rails 8.1 also generates `bin/ci` / `config/ci.rb`, which runs no specs.

It does **not** provide: the SonarQube project and secrets, Git-flow branches, installed git hooks, or project README
content.

## 3. Prerequisites

- **Ruby** through a version manager (rvm, rbenv, mise, asdf). The generated `.ruby-version` is the Ruby that
  runs `rails new`, so pick it deliberately: ask, defaulting to the newest stable Ruby the team uses. The
  template has been run on Ruby 3.4.7 and 4.0.6.
- **Rails**: use the newest released minor. The template pins the generated Gemfile to the generator's Rails
  version, and Brakeman's EOLRails check (Medium confidence) fails both CI and the verification once that minor
  nears end of support. For example, Rails 8.0 ends on 2026-11-07. Check
  `gem list '^rails$'` and `gem search '^rails$' --remote`, install with
  `gem install rails -v <version> --no-document`, and generate with `rails _<version>_ new` so the version is
  explicit. Tested with Rails 8.1.4.
- **PostgreSQL** running locally (`pg_isready`; Homebrew installs it under `/opt/homebrew/opt/postgresql@<n>/bin`,
  which may not be on `PATH`), with the current OS user allowed to create databases. The template runs
  `db:prepare`.
- **Docker**: the template ships a Dockerfile and Compose files, so Docker is always verified (section 6). Docker
  Desktop or another runtime with Compose v2, daemon running. The image is `linux/amd64`, like the CI runners,
  so on Apple silicon it builds and runs under emulation. That is slower (the first build takes a few minutes),
  and Compose warns that the platform does not match; both are expected.
- Network access (bundle install, template downloads) and a working `git` (`rails new` runs `git init`).
- **Non-interactive shells** may not load the version manager, leaving `ruby` as macOS's system Ruby 2.6, which
  cannot even parse the Gemfile. Run Ruby commands through the manager: `~/.rvm/bin/rvm <version> do <cmd>`,
  `rbenv exec <cmd>`, `mise exec ruby@<version> -- <cmd>`. Check `<prefix> ruby -v` first. This includes
  `git commit` once Overcommit is installed, because its hook is a Ruby script.

## 4. Generate

Generate into the current directory, which already holds the AI configuration and the checklist, both
committed. Keep the log outside the project:

```bash
log=$(mktemp "${TMPDIR:-/tmp}/generate.XXXXXX")
[DEV_MODE=true] <ruby prefix> rails _<version>_ new . \
  --api --database=postgresql --skip-test --skip-kamal --skip-thruster \
  --template=<template> < /dev/null > "$log" 2>&1
```

- The directory name becomes the app module (`doer_be_api` becomes `DoerBeApi`). If the app name the user gave
  differs from the directory name, or the directory name is not snake_case, add `--name=<app_name>`.
- `< /dev/null` keeps generator prompts from blocking. A conflict then resolves to "overwrite", which is
  intended: the template replaces generated defaults on purpose.
- It takes 3 to 6 minutes. Run it in the background and wait for it to exit.

Then check the log. It contains ANSI color codes, so strip them before searching:

```bash
sed 's/\x1b\[[0-9;?]*[A-Za-z]//g' <log> |
  grep -nE '^\s+conflict\s|aborted|could not|undefined method|uninitialized constant|NameError|NoMethodError'
```

Expected and harmless:

- `conflict` for `.gitattributes` (and for `README.md` if the directory had one)
- `The name 'User' is either already used in your application`: the Devise model generator collides with
  `data/user.rb`; the migration is still created.
- `BlueprintPolicyExtractor not found`: printed during early boots, before `infrastructure/` is copied.

Then protect the files from steps 1 and 2: `git status --short .claude .claudeignore .gitattributes PROJECT_SETUP_CHECKLIST.md`.

- **`.gitattributes` always collides.** The AI baseline ships one and `rails new` writes its own. Restore the
  baseline file (`git checkout -- .gitattributes`), then append the Rails lines it lacks (`db/schema.rb` and
  `config/credentials*.yml.enc` attributes, `vendor/*`), so both sets of rules apply.
- Anything else under those paths that changed: restore it with `git checkout -- <path>`.
- Delete `.kamal/`; the project does not use Kamal.

## 5. Configure

1. **Credentials**: separate values for development and test, so a leaked test secret is not a development one.
   The YAML travels in an environment variable and a one-line Ruby "editor" writes it, so no plaintext secret
   file is created. `credentials:edit` prints the newly created key, so its output goes to `/dev/null` to keep
   the key out of the transcript. Replace `<ruby prefix>` literally (this works in bash and zsh):

   ```bash
   for env in development test; do
     CREDS_YAML="admin:
     username: admin
     password: $(<ruby prefix> ruby -rsecurerandom -e 'print SecureRandom.alphanumeric(24)')
   devise:
     jwt_secret_key: $(<ruby prefix> ruby -rsecurerandom -e 'print SecureRandom.hex(64)')
   " EDITOR="ruby -e 'File.write(ARGV.fetch(0), ENV.fetch(%(CREDS_YAML)))'" \
       <ruby prefix> bin/rails credentials:edit --environment "$env" > /dev/null 2>&1
   done
   for env in development test; do
     RAILS_ENV=$env <ruby prefix> bin/rails runner \
       'puts "#{Rails.env}: admin=#{RCreds.fetch(:admin, :username).present?} jwt=#{RCreds.fetch(:devise, :jwt_secret_key).to_s.size}"'
   done
   ```

   Keep the YAML lines inside the quotes flush with the indentation shown (`admin:` and `devise:` at column 0,
   their keys indented two spaces); YAML is whitespace-sensitive.

   The `*.key` files (`config/master.key`, `config/credentials/*.key`) are gitignored. Tell the user where they
   are and that the team shares them through a password manager. Admin pages need the admin login only outside
   development and test. Servers can take the same values from ENV (`ADMIN_USERNAME`, `ADMIN_PASSWORD`,
   `DEVISE_JWT_SECRET_KEY`), because r_creds reads ENV first.
2. **API docs**: `<ruby prefix> bundle exec rake docs:generate RAILS_ENV=test` writes `doc/api/*.json`, used by
   `/api/docs` and `/open_api_docs`. Commit `doc/api`, so servers show the docs.

## 6. Verify: the definition of green

Run the bundled script, passing the Ruby prefix when the version manager is not loaded:

```bash
RUBY_RUN="<ruby prefix>" <skill dir>/scripts/verify_rails.sh <app dir> [http://localhost:<port>]
```

| Check | What it runs | Why |
| --- | --- | --- |
| `dev_eager_load` | `bin/rails zeitwerk:check` | Boots and eager-loads everything: catches class-load and initializer errors |
| `test_eager_load` | the same with `CI=1 RAILS_ENV=test` | CI eager-loads the test environment |
| `production_eager_load` | the same with `RAILS_ENV=production`, credentials from ENV, the dev database via `DATABASE_URL` | Production config boots the way a server does |
| `specs` | `bundle exec rspec` | Test suite green |
| `ci_specs` | the CI test job on a copy of the working tree without credentials keys, with `CI=1` and ENV credentials | The suite also passes the way CI runs it; never moves the real keys |
| `rubocop` | `bundle exec rubocop` | House style clean |
| `brakeman` | Brakeman with the `.overcommit.yml` exclusions | Security scan clean; this also catches end-of-life Rails |
| `bundler_audit` | `bundler-audit check --update` | No gems with known vulnerabilities (CI and the git hook run it too) |
| `git_hooks` | `overcommit --run`, once installed | The commit hooks pass; stage everything first, because hooks only check the git index |
| `api_docs` | `rake docs:generate RAILS_ENV=test` plus files present | Docs and OpenAPI file are generated |
| `smoke_endpoints` | GET `/up`, `/`, `/api/docs`, `/open_api_docs`, `/jobs`, `/maintenance_tasks`, `/motor_admin` | Server and mounted tools answer 200 (needs a base URL) |
| `smoke_auth` | sign in, then profile, sign out, and profile again with the revoked token | JWT auth works end to end (needs a base URL; uses a throwaway user) |

Green means every check passes. Logs are in `tmp/setup-verify/` (gitignored with `tmp/`). Checklist ticks:
`specs` and `ci_specs` for "Tests pass"; `rubocop`, `brakeman` and `bundler_audit` for "Linters and security scans
clean"; every check, with the base URL, for "Runs locally"; `verify_rails_docker.sh` for "Runs in Docker".

`api_docs` rewrites about 10 committed files in `doc/api` on every run with per-run values (tokens, Faker data,
timestamps, request ids), and the script prints a NOTE when it did. If no spec changed, restore them with
`git checkout -- doc/api` instead of committing the churn.

### Docker

The template ships a Dockerfile and Compose files, so green also needs the Docker checks (SKILL.md, "Docker
setup"). Make the "CI and Docker" changes from section 8 first, then run the second script with a working `git`
first on `PATH`, because it reads the entrypoints' git mode:

```bash
<skill dir>/scripts/verify_rails_docker.sh <app dir>
```

| Check | What it runs | Why |
| --- | --- | --- |
| `docker_daemon` | the docker CLI and daemon (finds the runtime's own CLI when the `docker` symlink dangles; `DOCKER_BIN` overrides) | Nothing else runs without it |
| `compose_config` | `docker compose config -q` for the `development` and `cicd` profiles | The Compose files and `stack.env` are valid |
| `entrypoints` | `docker-entrypoint*.sh` executable on disk and `100755` in git | The bind mount hides the image's `chmod`, and CI uses the git mode |
| `ci_workflow` | `.github/workflows/docker_ci.yml` has no `<app_name>` left, its `APP_NAME` and `COMPOSE_PROJECT_NAME` prefix match `.env.test`, and the generator's `ci.yml` is gone | CI is fitted to this app and is the only workflow |
| `ci_specs` | the CI test job: profile `cicd`, `docker-entrypoint.test.sh`, its own Compose project, volumes removed afterwards | CI's container run passes, runs more than 0 examples, and writes `coverage/coverage.json` for Sonar |
| `dev_stack` | build and start profile `development`; `/up` answers; after 20 s every service is running with 0 restarts | The app boots in Docker, and no service (such as `jobs`) crash-loops |
| `smoke_endpoints` | the same GETs as the local check, against the container | Server and mounted tools answer from Docker |
| `smoke_auth` | sign in, profile, sign out, revoked token, with a throwaway user created inside the container | JWT auth works against the container's database |
| `jobs` | a Solid Queue worker with a recent heartbeat | The `jobs` service works |
| `storage` | `/var/www/storage` is a volume, and an Active Storage upload lands there | Uploads persist and stay out of the host's `storage/` |
| `host_assets` | no `public/assets/.manifest.json` on the host | Nothing precompiled assets in development through the bind mount |

The development stack reads the gitignored `stack.env`. When it is missing, the script creates it from `.env.test`
with `RAILS_ENV=development`. Host ports come from `RAILS_PUBLISHED_PORT` / `POSTGRES_PUBLISHED_PORT` (in the
environment or `stack.env`), else 3000 / 5432, or 3001 / 5433 when a local Rails server or PostgreSQL already
listens there. The CI run swaps `.env.test` in as `stack.env`, as CI does, and restores it afterwards. Both stacks
use the same fixed container names, so the script stops the development stack (keeping its volumes) before the CI
run, and starts it again at the end. It leaves the development stack running. Logs are
`tmp/setup-verify/docker_<check>.log`.

## 7. Run the server

Start it detached, so it survives the end of the session:

```bash
cd <app dir>
rm -f tmp/pids/server.pid   # only if the previous server is gone
SOLID_QUEUE_IN_PUMA=1 nohup <ruby prefix> bin/rails server -p <port> > ../<app>-server.log 2>&1 < /dev/null & disown
```

Use port 3000, or the next free one: `lsof -nP -i :<port> -sTCP:LISTEN` (without `-nP`, ports show as service
names such as `hbci` for 3000). `SOLID_QUEUE_IN_PUMA=1` runs the jobs worker inside Puma, so `/jobs` shows a live
worker; `bin/jobs` runs it separately. Wait for `/up` to answer, then run the verification with the base URL.
To stop it: `kill $(lsof -t -nP -i :<port> -sTCP:LISTEN)`.

`verify_rails_docker.sh` leaves the Docker development stack running beside it, on 3001 when the local server
has 3000. Restart it with `docker compose --env-file stack.env --profile development up -d`, and stop it with
`... down`. Both apps share the working directory through the bind mount, but not their databases.

## 8. Remaining checklist items

| Item | How | Tick when |
| --- | --- | --- |
| Git-flow branches | Create `staging` and `production` from `dev` locally. Push only once the repository exists and the user agrees | Created locally ticks the local Git item; pushing them is the repository item |
| Git hooks | First add `.claude/**/*`, `.agents/**/*` and `.github/skills/**/*` to `PreCommit: ALL: exclude` in `.overcommit.yml`: the AI baseline ships placeholder `.rb` files that the RuboCop hook would fail on. Then `<ruby prefix> bundle exec overcommit --install && <ruby prefix> bundle exec overcommit --sign`, stage everything (`git add -A`) and run `<ruby prefix> bundle exec overcommit --run`. Commit with `<ruby prefix> git commit` | `.git/hooks/pre-commit` exists and `git_hooks` passes on the staged tree |
| README / CHANGELOG | Replace the example README (a fictional tour-booking project) with this project's README: purpose, stack, prerequisites, setup (credentials, `bin/rails db:prepare`, hooks), running (server, jobs), tests, lint, API docs, Git-flow, links (Jira, Confluence, Figma; mark them TBD for the owner if unknown), and the server environment: `RAILS_MASTER_KEY` or `ADMIN_USERNAME` / `ADMIN_PASSWORD` / `DEVISE_JWT_SECRET_KEY`, and `MOTOR_AUTH_USERNAME` / `MOTOR_AUTH_PASSWORD` (Motor Admin is open without them). Reset `CHANGELOG.md` to an `Unreleased` section | Committed |
| CI | See "CI and Docker" below | Workflow and its prerequisites committed; `ci_specs`, `rubocop`, `brakeman` and `bundler_audit` pass locally, and the Docker `ci_specs` passes. Tick "first CI run on GitHub is green" only after a real run |
| Docker | See "CI and Docker" below, then `verify_rails_docker.sh` (section 6), in step 6 of the workflow | `verify_rails_docker.sh` passes on this machine. Without a working Docker runtime it stays unticked with `-> <who>`, even when the files look right |
| SonarQube | DevOps creates the project (key = repository name); the CI workflow already runs the analysis with coverage once `SONAR_URL` / `SONAR_TOKEN_2025` are set | Leave to DevOps |

### CI and Docker (doer_be_api pattern)

`.github/workflows/docker_ci.yml` follows doer_be_api's CI:

- RuboCop, Brakeman and bundler-audit run on the runner.
- The specs run inside Docker Compose.
- SonarQube analysis, with the coverage report, runs in the same job.

The specs job only works once the project's Docker setup is CI-ready. The template provides steps 1 to 9; older
template revisions do not, so check each one and apply what is missing, even if Docker is not available on this
machine. Step 1 always needs a look: the workflow must fit this project. The steps mirror doer_be_api's working
setup, and avoid what doer_be_api still does: a committed CI credentials key, precompiling assets in development,
and fixed host ports. Then verify them with `verify_rails_docker.sh` (section 6). If you had to apply any of steps
2 to 9, the app came from an older template revision: note that in one line in the checklist's Notes.

1. `.github/workflows/docker_ci.yml`, fitted to this project. The template writes it from its
   `github/workflows/docker_ci.yml` (no leading dot, so GitHub does not run it in the template repository) with
   the app name filled in, and deletes the generator's `.github/workflows/ci.yml`, which runs no specs and only
   triggers on `main`. On an older template revision, copy that file from the template repository's `main`,
   replace `<app_name>`, and delete `ci.yml`. Then check, and update what does not fit:
   - `APP_NAME` and the `COMPOSE_PROJECT_NAME` prefix (top-level `env:`) are the app name, the same as `APP_NAME`
     in `.env.test`, with no `<app_name>` left;
   - `runs-on: [self-hosted, coax]` (both jobs) for a repository in the `coaxsoft` organization, `ubuntu-latest`
     for a client organization without COAX runners;
   - triggers: pull requests to `dev` and `production`, per the Wiki; add `staging` or `preprod` when the
     project's Git-flow has them;
   - SonarQube: `projectKey` is the repository name, and the secrets are `SONAR_URL` and `SONAR_TOKEN_2025` (the
     COAX token, as in doer_be_api; the Wiki's older `SONAR_TOKEN` name is not used).

   `verify_rails_docker.sh` checks the names and that `ci.yml` is gone (`ci_workflow`); read the file for the
   rest.
2. `.env.test` (the template writes it; otherwise create it from [../assets/rails/env.test](../assets/rails/env.test)),
   with the app name, and the Ruby version from `.ruby-version` without the `ruby-` prefix. It holds test-only values and is committed: add
   `!/.env.test` and `stack.env` to `.gitignore`, because Rails ignores `/.env*`. CI copies it to `stack.env`.
3. In the `default:` section of `config/database.yml`, read the connection through r_creds, as doer_be_api does.
   Containers then reach the `postgres` service through `POSTGRES_*` from `stack.env`; local runs get empty
   values and keep using the socket:

   ```yaml
   username: <%= RCreds.fetch(:postgres, :user) %>
   password: <%= RCreds.fetch(:postgres, :password) %>
   host: <%= RCreds.fetch(:postgres, :host) %>
   port: <%= RCreds.fetch(:postgres, :port) %>
   ```
4. `docker-compose.yml`:
   - Remove the `redis` service, `redis` from the `rails` service's `depends_on`, and the `redis_data` volume.
     The app has no Redis, and with no `REDIS_VERSION` in `.env.test` Compose cannot pull `redis:`.
   - Mount the app as `'.:/var/www'` instead of `'.:/var/www/${APP_NAME}'`, so the coverage report the specs
     write lands in the runner's workspace.
   - Publish host ports through variables that default to the current values, so the stack also runs next to a
     local PostgreSQL or Rails server: `"${POSTGRES_PUBLISHED_PORT:-5432}:5432"` and
     `"${RAILS_PUBLISHED_PORT:-3000}:3000"`.
   - Use `networks: app-net: {}` instead of `name: app-net`. A fixed global name collides between projects and CI
     runs on one host; doer_be_api moved to the project-scoped name too.
   - Add a named volume for Active Storage: `rails_storage:/var/www/storage` on `rails`, and `rails_storage: {}`
     under `volumes:`.
   - Add the `development` profile to `postgres`, `rails` and `jobs`, so the local stack starts with
     `--profile development`, as in doer_be_api.
   - Give `rails` a health check (`curl -fs http://localhost:3000/up`), and make `jobs` depend on
     `rails: condition: service_healthy` with `healthcheck: disable: true`. On a fresh volume the queue database
     exists only after the `rails` entrypoint's `db:prepare`, so `jobs` would crash once on first boot.
   - Drop the obsolete `version:` key, in `docker-compose.test.yml` too.
5. `Dockerfile`:
   - `FROM --platform=linux/amd64 ruby:<.ruby-version without "ruby-">` instead of `ruby:3.2.3`.
   - `ENV RAILS_ROOT=/var/www`, matching the mount.
   - Install the Bundler the lockfile was written with, instead of the newest one:
     `RUN gem install bundler -v "$(awk '/BUNDLED WITH/ { getline; print $1 }' Gemfile.lock)"`.
6. Entrypoints: `chmod +x docker-entrypoint*.sh`, so git stores them as `100755`. The template downloads them as
   `644`. The image's `chmod` does not help: the bind mount replaces the files with the host's copies. Without
   this, the `jobs` service and CI's `--entrypoint=./docker-entrypoint.test.sh` fail with `permission denied`.
7. `docker-entrypoint.sh`: precompile assets only outside development. In development the app directory is
   bind-mounted, so precompiled `public/assets` would make both the container and the local server ignore asset
   changes:

   ```sh
   if [ "$RAILS_ENV" != "development" ]; then
     bundle exec rails assets:precompile
   fi
   ```
8. `docker-entrypoint.test.sh`: drop `--exclude-pattern acceptance` from the `rspec` line. In a fresh app every
   spec is an acceptance spec, so CI would run 0 examples and still pass.
9. Coverage: `spec/support/simplecov_profile.rb` writes `coverage/coverage.json`, which the workflow checks and
   Sonar reads. Add `/coverage/` to `.gitignore` so local runs never commit it.
10. Secrets `SONAR_URL` and `SONAR_TOKEN_2025` come once the repository and the SonarQube project exist ->
    DevOps.

Verify: `ci_specs` and the lint checks from `verify_rails.sh`, then `verify_rails_docker.sh`, which also runs the
CI test job in Docker (section 6).

The Dockerfile now installs Bundler as a regular gem, so `bundle install` in a container adds a
`bundler (<version>) sha256=...` line under `CHECKSUMS` in `Gemfile.lock` (through the bind mount). A host whose
Bundler is a default gem drops that line again. Commit it, as doer_be_api does, and on the host run
`gem install bundler -v <BUNDLED WITH version>` so both sides agree.

## 9. Known failures

| Symptom | Cause | Fix |
| --- | --- | --- |
| `` `windows` is not a valid platform `` from Bundler | macOS system Ruby 2.6 (version manager not loaded) | Run through the version manager (see Prerequisites) |
| `Bad CPU type in executable` / `Errno::EBADARCH` mentioning git | A broken git binary is first on `PATH` | Put a directory with a symlink to a working git first on `PATH` |
| Dozens of `already initialized constant RDoc::...` warnings from `gem` | Two rdoc versions installed | Harmless |
| `Sprockets::Railtie::ManifestNeededError` | An old template revision (railsbytes, or an old branch) | Use the current template |
| `undefined method 'assets' for an instance of Rails::Engine::Configuration` from `apitome/engine.rb` during generation; the log shows `rspec-rails (~> 4.0, >= 4.0.1)`, `fakeredis` and `app/assets/config/manifest.js` | GitHub `main` serves an old template revision (the current one is not merged yet) | Merge the current template into `main`, then clean the directory back to the setup commits (`git checkout -- . && git clean -fdx`) and regenerate |
| `OpenURI::HTTPError 404` during generation | `template.rb` downloads a file that is not committed on `main` | Commit the file and merge it to `main` |
| `uninitialized constant Pagy::Backend` | Pagy 43 resolved | The template pins `pagy ~> 9.4`; check the Gemfile |
| `ArgumentError: Expected name: to be a String, got NilClass` on eager load | Admin credentials missing (class-level `http_basic_authenticate_with`) | Configure credentials (Configure step 1) |
| Brakeman `EOLRails`: "Support for Rails X ends on ..." | The project was generated with an ageing Rails minor | Regenerate with the newest Rails (Prerequisites) |
| `PG::ConnectionBad` / `DatabaseConnectionError` in production eager load | No reachable database: `Search::Users` reads the users schema at class load | Expected without a database; the check borrows the dev one. Rake tasks (`db:prepare`, `assets:precompile`) do not eager-load, so a first deploy works |
| `ActiveRecord::NoDatabaseError` from `db:prepare` on a new production database | A template older than the `ApplicationRecord#action_scope` guard | Use the current template |
| `ActiveSupport::MessageEncryptor::InvalidMessage` when imitating CI by moving `test.key` aside | Rails falls back to `config/master.key`, which CI does not have | Use `ci_specs`, which runs on a copy without any keys |
| Overcommit RuboCop: many `Lint/Syntax` offenses in `.claude/skills/**/templates/*.rb` | The hook passes file paths explicitly, so it lints the AI baseline's placeholder snippets (plain `rubocop` skips hidden dirs) | Exclude `.claude/**/*`, `.agents/**/*`, `.github/skills/**/*` in `.overcommit.yml` `PreCommit: ALL` (template issue) |
| The pre-commit hook says "passed" but runs nothing | `git commit` under the system Ruby, or nothing staged | Commit through the Ruby prefix; stage files first |
| SimpleCov `0 / 0 LOC` under `CI=1` | `spec/rails_helper.rb` starts SimpleCov after loading the eager-loaded environment | Template issue: require and start SimpleCov before `config/environment` (and drop the second `SimpleCov.start` in `spec/support/simplecov_profile.rb`); add `/coverage/` to `.gitignore` |
| `Generating image variants with libvips requires the ruby-vips gem` | `image_processing` 2.x no longer pulls `ruby-vips` | Template issue: add `gem 'ruby-vips'` (and libvips in Docker) before using variants |
| `/api/docs` 500, "Unable to find doc/api/index.json" | Docs not generated | `rake docs:generate RAILS_ENV=test` |
| `JWT::EncodeError` or nil-secret errors in specs | Test credentials missing | Configure them (Configure step 1) |
| `A server is already running` / port in use | Stale `tmp/pids/server.pid`, or another process on the port | Remove the pid file once the old process is gone, or pick another port |
| Docker: `env file stack.env not found`; the `rails` service waits for `redis`; `invalid reference format` for `redis:`; the image is `ruby:3.2.3` | Template Docker files lag the template | Apply "CI and Docker" steps 2 to 5 (older template revision) |
| CI test job green with `0 examples` | `docker-entrypoint.test.sh` excludes `spec/acceptance`, and a fresh app has only acceptance specs | "CI and Docker" step 8 (older template revision) |
| CI: `Verify coverage report` fails | The app is mounted at `/var/www/<app>` while the image works in `/var/www`, so the report never reaches the runner | "CI and Docker" steps 4 and 5 (older template revision) |
| `Cannot connect to the Docker daemon at unix:///.../docker.sock` | The runtime is installed but not running | Start it (`open -a Docker`) and wait until `docker version` shows a server |
| `docker: command not found`, or `/usr/local/bin/docker` pointing into an uninstalled runtime (such as OrbStack) | A dangling CLI symlink | Use the installed runtime's CLI, e.g. `/Applications/Docker.app/Contents/Resources/bin/docker`; `verify_rails_docker.sh` finds it |
| `jobs` keeps restarting with `exec ./docker-entrypoint-jobs.sh: permission denied`; CI fails the same way on `docker-entrypoint.test.sh` | Entrypoints committed as `644`; the bind mount hides the image's `chmod` | "CI and Docker" step 6 (older template revision) |
| `Warning: You are precompiling assets in development`, and `public/assets/` appears on the host | `docker-entrypoint.sh` precompiles in every environment, through the bind mount | "CI and Docker" step 7, then delete `public/assets` (older template revision) |
| `jobs` restarts once on the first boot: `Database not found: <app>_development_queue` | `jobs` starts before the `rails` entrypoint's `db:prepare` has created the queue database | "CI and Docker" step 4: `jobs` waits for a healthy `rails` (older template revision) |
| `jobs` in production: `The --without flag has been removed` | Bundler 4 dropped `bundle install --without`, which the jobs entrypoint used | `export BUNDLE_WITHOUT=development:test` before `bundle install` in `docker-entrypoint-jobs.sh` (older template revision) |
| `Bind for 0.0.0.0:5432 failed: port is already allocated` (or 3000) | A local PostgreSQL or Rails server holds the host port | Set `POSTGRES_PUBLISHED_PORT` / `RAILS_PUBLISHED_PORT` ("CI and Docker" step 4); never stop the user's services |
| `Conflict. The container name "/<app>_postgres" is already in use` | The development stack and a CI-style run share fixed `container_name`s | Run them one after the other; `verify_rails_docker.sh` stops the development stack first |
| `network app-net was found but has incorrect label` | A fixed-name `app-net` left by another project or run | `docker network rm app-net`, and use the project-scoped network ("CI and Docker" step 4) |
| `Gemfile.lock` gains or loses `bundler (<version>) sha256=...` under `CHECKSUMS` | Containers install Bundler as a regular gem and add its checksum; a host Bundler that is a default gem drops it | Keep the line committed; on the host, `gem install bundler -v <BUNDLED WITH version>` |
| `The requested image's platform (linux/amd64) does not match the detected host platform` | The amd64 image on Apple silicon | Expected; it runs under emulation |
| `command not found: docker compose --env-file ...` in zsh | zsh does not word-split a command stored in a variable | Spell the command out, or run it under bash, as the scripts do |
