# Other technologies: templates and how to automate them

The Wiki's [Project setup](https://coaxsoftware.atlassian.net/wiki/spaces/CXWB/pages/19169903/Project+setup)
page lists the official starting point for each stack. Only Rails is automated so far. For the others, the
technology-independent steps still apply: step 1 (git and AI configuration), step 2 (checklist), step 7
(`AGENTS.md`) and step 9 (commit). Generate, configure and verify by hand, following the template's own README,
and tick the checklist as you go.

| Technology | Template | AI config tier | Standard linters / tools |
| --- | --- | --- | --- |
| Python (Django) | [coaxsoft/cxcx_django_base_cookiecutter](https://github.com/coaxsoft/cxcx_django_base_cookiecutter) | `python` | flake8 and bandit through pre-commit (see [Git-flow](https://coaxsoftware.atlassian.net/wiki/x/L4AjAQ)), [Python Tools](https://coaxsoftware.atlassian.net/wiki/x/WYUjAQ) |
| Node.js (NestJS) | [coaxsoft/cxcx_be_nestjs_template](https://github.com/coaxsoft/cxcx_be_nestjs_template) | `nodejs` | [@coaxsoft/eslint-config-be](https://www.npmjs.com/package/@coaxsoft/eslint-config-be), [Node.js Tools](https://coaxsoftware.atlassian.net/wiki/x/LIQkAQ) |
| React / Next.js | [React/Next bootstrap](https://coaxsoftware.atlassian.net/wiki/spaces/CXWB/pages/19235655/React+Next+bootstrap) | `react` | [@coax/eslint-config-fe-react](https://www.npmjs.com/package/@coax/eslint-config-fe-react), [Front-end Tools](https://coaxsoftware.atlassian.net/wiki/x/vwMlAQ) |
| React Native | None listed on the Wiki | `react-native` | Not defined on the Wiki |

Confirm the template with the competence lead first. The Wiki says to ask when a stack has no template listed,
which today is React Native: agree the starting point, linters and hook tool, and note them in the checklist.

The checklist is the same for every stack. What its items mean here:

| Checklist item | Python (Django) | Node.js (NestJS) | React / Next.js | React Native |
| --- | --- | --- | --- | --- |
| Git hooks installed | pre-commit ([Git-flow](https://coaxsoftware.atlassian.net/wiki/x/L4AjAQ)) | not defined on the Wiki: agree it | not defined on the Wiki: agree it | not defined on the Wiki: agree it |
| Runs locally | dev server answers its health check | dev server answers its health check | dev server serves the app, and the production build succeeds | app builds and launches on an iOS simulator and an Android emulator |
| Runs in Docker | required | required | required (dev server or production build) | usually `[-]`, unless the project ships its own services |

Whenever the template ships Docker files, validate and fix the Docker setup as `SKILL.md` describes ("Docker
setup"): build the image, start the development stack, check the app from its container, and run CI's container
run when CI uses one. Use the commands from the template's README, since these stacks have no bundled script yet.

## Adding a technology reference

Once a template is reliable enough to automate, add `references/<technology>.md` with the same sections as
[rails.md](rails.md), so `SKILL.md` can drive it unchanged:

1. **Template source**: canonical location and branch, the local-checkout mode for template development, and any
   stale copies to avoid.
2. **What the template provides**: what it covers and what it does not, so checklist items are ticked honestly.
3. **Prerequisites**: toolchain and versions, services (database, cache), and shell pitfalls (version managers,
   PATH).
4. **Generate**: the exact non-interactive command, expected harmless warnings, and the files known to collide
   with the AI configuration (for example `.gitattributes`).
5. **Configure**: secrets and environment files, generated docs, seed data.
6. **Verify: the definition of green**: build or boot, tests (locally and as CI runs them), linters, security
   scan, and checks against the running app (health check, pages, or a simulator launch). Prefer a
   bundled `scripts/verify_<technology>.sh` that prints PASS/FAIL per check. When the template ships Docker files,
   add a Docker verification too (`scripts/verify_<technology>_docker.sh`, modelled on
   `verify_rails_docker.sh`), plus the Docker fixes the template needs.
7. **Run the app**: command, port or simulator/emulator, background-job workers, and how to keep it running.
8. **Remaining checklist items**: how to automate and verify Git hooks, CI, Docker, README for this stack.
9. **Known failures**: symptom, cause, fix. Grow it from real setup runs.

Then add the technology to the table in `SKILL.md`. Ship the CI workflow from the template itself, as
rails_prototype does with `github/workflows/docker_ci.yml`, and say in the reference how to fit it to the project.
