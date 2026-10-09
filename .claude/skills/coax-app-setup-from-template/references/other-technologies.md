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
which today is React Native: agree the starting point, linters and hook tool, and record them in the checklist.

The checklist is technology-agnostic. Its "What the items mean for your stack" table maps every item to these
stacks (hook tool, linters, what "runs locally" means, whether Docker applies), so use it as written. Mobile apps
mark the Docker section `[-]` with the reason, unless the project ships its own services.

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
   bundled `scripts/verify_<technology>.sh` that prints PASS/FAIL per check.
7. **Run the app**: command, port or simulator/emulator, background-job workers, and how to keep it running.
8. **Remaining checklist items**: how to automate and verify Git hooks, CI, Docker, README for this stack.
9. **Known failures**: symptom, cause, fix. Grow it from real setup runs.

Then add the technology to the table in `SKILL.md` and, if its CI differs, add `assets/<technology>/ci.yml`.
