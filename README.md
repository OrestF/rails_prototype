# COAX Rails API template

[`template.rb`](template.rb) is a [Rails application template](https://guides.rubyonrails.org/rails_application_templates.html)
that generates a Rails 8 API app on the COAX backend stack. That stack covers JWT authentication, role-based
authorization, the ABDI layout, generated API docs, admin tools, Docker, and CI with SonarQube.

The other files in this repository are the files the template copies into the new app. Each one sits at the path
where it lands in the generated app.

## Create an app

### Prerequisites

- **Ruby**, installed through a version manager (rvm, rbenv, mise). The generated `.ruby-version`, Dockerfile and
  RuboCop target all use the Ruby that runs `rails new`.
- **Rails**, the newest released minor (`gem install rails -v <version>`). The generated Gemfile pins Rails to the
  generator's version. Brakeman fails CI once that minor nears its end of support.
- **PostgreSQL**, running locally, with your OS user allowed to create databases. The template runs `db:prepare`.
- **git** and network access. The template downloads its files from this repository on GitHub.

Tested with Rails 8.1 on Ruby 3.4 and 4.0.

### Generate

Name the app like its GitHub repository: `<codename>_be_api`, for example `doer_be_api`.

```bash
rails _8.1.4_ new <codename>_be_api \
  --api --database=postgresql --skip-test --skip-kamal --skip-thruster \
  --template=https://raw.githubusercontent.com/OrestF/rails_prototype/main/template.rb
```

Generation takes a few minutes. It ends by running `rubocop -A` and printing the next steps. These messages in the
output are expected:

- `conflict .gitattributes`, and `conflict README.md` if the directory had one. The template overwrites generated
  defaults on purpose.
- `The name 'User' is either already used in your application`. The Devise generator runs into `data/user.rb`, but
  it still creates the migration.
- `BlueprintPolicyExtractor not found`. Early boots print it before `infrastructure/` is copied in.

> The Wiki's Project setup page links a railsbytes template (`Xo5s6a`). That is an older revision with Redis and
> Sidekiq, so use the command above instead.

### Or let Claude Code do it

The `coax-app-setup-from-template` skill ([source](.claude/skills/coax-app-setup-from-template/SKILL.md)) runs the
whole setup inside a new, empty project directory. It imports the COAX AI config, generates the app from this
template and sets up credentials. It then verifies tests, linters and Docker, and tracks the Wiki's project setup
steps in `PROJECT_SETUP_CHECKLIST.md`. To start it, ask Claude to "create a new Rails application" from that
directory.

### After generating

1. **Credentials.** Create them for development and for test, with different values in each:

   ```bash
   bin/rails credentials:edit --environment development
   bin/rails credentials:edit --environment test
   ```

   ```yaml
   admin:
     username: admin
     password: <strong password>
   devise:
     jwt_secret_key: <output of bin/rails secret>
   ```

   The `config/credentials/*.key` files are gitignored, so share them through the team's password manager.
2. **API docs.** Run `bundle exec rake docs:generate RAILS_ENV=test` and commit `doc/api`, so that servers can show the docs.
3. **Git hooks.** Run `bundle exec overcommit --install && bundle exec overcommit --sign`.
4. **Project docs.** `README.md` and `CHANGELOG.md` are generic examples. Replace them with the project's own.
5. **Kamal.** Delete `.kamal/`. The template creates it even with `--skip-kamal`, but nothing uses it.

## What the generated app includes

| Area | Included |
| --- | --- |
| Framework | Rails API, PostgreSQL, Propshaft |
| Jobs, cache, cable | Solid Queue (in development too, with its own queue database), Solid Cache, Solid Cable. No Redis |
| Authentication | Devise with JWT (devise-jwt, JTI revocation), invitable and lockable, under `/api/v1/users` |
| Authorization | Pundit policies, with role permissions from Passpartu (`business/permissions.yml`) |
| Business logic | ABDI layers built on Readymade forms, operations and actions |
| Serialization, pagination | Blueprinter, Oj, Pagy with api-pagination |
| Tests | RSpec, FactoryBot, Faker, DatabaseCleaner, SimpleCov, plus acceptance specs for auth and profile |
| API docs | rspec_api_documentation produces the Apitome docs (`/api/docs`) and an OpenAPI file (`/open_api_docs`) |
| Code quality | RuboCop (rails-omakase plus house rules), Brakeman, bundler-audit, fasterer, RubyCritic, Bullet, an Overcommit config |
| Admin and ops | Motor Admin, maintenance_tasks, Mission Control Jobs, and a development home page that links to them |
| Config and logging | r_creds (reads ENV first, then Rails credentials), xlog middleware |
| Docker | Dockerfile and Compose with `postgres`, `rails` and `jobs` services, profiles `development` and `cicd` |
| CI | `.github/workflows/docker_ci.yml`: linters on the runner, specs in Docker Compose, SonarQube with coverage |

### Layout (ABDI)

The app follows the [ABDI](https://gist.github.com/OrestF/084f7cb38c16084234f4c41338c364dc) layout: `app`,
`business`, `data`, `infrastructure`.

```text
app/
  controllers/api/        JSON API: Devise controllers and v1 resources
  policies/               Pundit policies
  serializers/            Blueprinter serializers
  services/               search and direct uploads
business/
  <domain>/forms/         permitted and required attributes, validation
  <domain>/operations/    use cases: build the form, then save the record
  permissions.yml         role permissions read by Passpartu
data/                     Active Record models and their concerns (replaces app/models)
infrastructure/           BaseOperation, BaseForm, BaseAction, BaseSearch, BaseResponse
spec/acceptance/          API specs that also generate the API docs
```

`PATCH /api/v1/users/profile` shows the request flow:

1. `Api::BaseController` authenticates the JWT.
2. The `Authorizer` concern requires a Pundit check on every action.
3. `Api::V1::UsersController` calls `Users::Operations::Update`.
4. That operation validates the params through `Users::Forms::Update`, then saves the record.

### Routes

| Path | What | Access |
| --- | --- | --- |
| `/` | Development home page | Open |
| `/api/v1/users/...` | Devise: sign in, sign out, sign up, password reset, invitations | Open or JWT |
| `/api/v1/users/profile` | `GET` and `PATCH` the current user | JWT |
| `/api/docs` | Apitome API docs | Open |
| `/open_api_docs` | Download `doc/api/open_api.json` | Admin basic auth outside development and test |
| `/jobs` | Mission Control Jobs | Admin basic auth outside development and test |
| `/maintenance_tasks` | Maintenance tasks | Admin basic auth outside development and test |
| `/motor_admin` | Motor Admin | `MOTOR_AUTH_USERNAME` / `MOTOR_AUTH_PASSWORD` |
| `/up` | Health check | Open |

## Working on a generated app

```bash
bin/rails server                                  # API on :3000
bin/jobs                                          # Solid Queue worker
SOLID_QUEUE_IN_PUMA=1 bin/rails server            # or both in one process

bundle exec rspec
bundle exec rubocop
bundle exec brakeman --exit-on-warn --except MassAssignment,PermitAttributes,SendFile
bundle exec bundler-audit check --update
bundle exec rake docs:generate RAILS_ENV=test     # writes doc/api/*.json
```

### Docker

Compose reads the gitignored `stack.env`. Create it once from the committed `.env.test`:

```bash
sed 's/^RAILS_ENV=test$/RAILS_ENV=development/' .env.test > stack.env
docker compose --env-file stack.env --profile development up --build
```

If ports 3000 or 5432 are already taken on the host, set `RAILS_PUBLISHED_PORT` or `POSTGRES_PUBLISHED_PORT` to
free ones. The image is `linux/amd64` to match the CI runners, so on Apple silicon it runs under emulation.

### Server environment

r_creds reads ENV before credentials, so a server can use either `RAILS_MASTER_KEY` or these variables:

| Variable | Used for |
| --- | --- |
| `ADMIN_USERNAME`, `ADMIN_PASSWORD` | Basic auth for `/jobs`, `/maintenance_tasks`, `/open_api_docs` |
| `DEVISE_JWT_SECRET_KEY` | Signing JWTs |
| `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_HOST`, `POSTGRES_PORT` | Database connection |
| `MOTOR_AUTH_USERNAME`, `MOTOR_AUTH_PASSWORD` | Motor Admin login. **Without them, `/motor_admin` is open** |

### CI

The workflow runs on pull requests to `dev` and `production`, and on manual dispatch. To work, it needs:

- the COAX self-hosted runners (`[self-hosted, coax]`). In a client's GitHub organization, use `ubuntu-latest` instead.
- the `SONAR_URL` and `SONAR_TOKEN_2025` repository secrets.
- a SonarQube project whose key is the repository name. DevOps creates it.

CI needs no credentials key, because the workflow sets test credentials through ENV.

## Maintaining the template

`template.rb` fetches each file with `download_file '<path>'` from the `main` branch of this repository on GitHub. A
file's path here is its path in the generated app, with these exceptions:

| Here | In the generated app |
| --- | --- |
| `github/workflows/docker_ci.yml` | `.github/workflows/docker_ci.yml`, with `<app_name>` filled in. It has no leading dot here, so it does not run on this repository |
| `README_EXAMPLE.md`, `CHANGELOG_EXAMPLE.md` | `README.md`, `CHANGELOG.md` |
| `.env.example` | `.env` |

To add a file, put it at its path in the generated app, then add a `download_file` call to the matching setup method
in `template.rb`. Some files here are not downloaded any more but stay for projects that opt back in: Sidekiq,
Redis, Searchkick, sweet_staging, rails_performance, VCR, fakeredis.

### Test changes locally

Run this from the directory that contains your checkout:

```bash
DEV_MODE=true rails new test_app \
  --api --database=postgresql --skip-test --skip-kamal --skip-thruster \
  --template=rails_prototype/template.rb
```

`DEV_MODE` copies files from the checkout instead of downloading them, and that includes untracked files. So a run
that passes locally can still fail with a 404 from GitHub. Commit every file that `template.rb` downloads before you
merge to `main`.

### Branches

`main` is the only branch the template downloads from. Everyone who generates an app gets whatever is on `main`, so
merge only changes that generate a working app. `master` and the other branches are older revisions, including the
Rails 6 `setup.sh`.

When the template changes, also update the setup skill's Rails reference
([references/rails.md](.claude/skills/coax-app-setup-from-template/references/rails.md)), which describes what the
template produces.
