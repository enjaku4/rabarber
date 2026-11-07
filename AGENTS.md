# AGENTS.md

A high-level picture of the gem for anyone working on it, including AI agents. What the gem does and how to use it is in README.md; how something is done is in the code.

## Keeping this file current

- When the architecture or a rule changes, update this file in the same change. Replace what no longer holds; don't keep history here, git has it.
- Describe the architecture, not the implementation: leave out details that change with the code.
- Keep entries short.

## Commands

- `bin/setup` installs the dependencies.
- `bin/rspec` runs the specs; `UUID_TESTS=true bin/rspec` runs them against a schema with UUID primary keys.
- `bin/rubocop` runs the linter, including on the README's code examples.
- Both the specs and the linter must pass.

## Code map

- `Rabarber::Configuration`: the app's settings.
- `Rabarber::Engine`: connects Rabarber to the app. It adds `Rabarber::Roleable` to the configured user model when that model loads, clears the authorization rules when the app reloads its code, makes the migration helpers available, and registers Rabarber's deprecation warnings with the app, so the app's deprecation settings apply to them.
- `Rabarber::Roleable`: what the user model gets: assigning, revoking and checking the user's roles.
- `Rabarber::Role`: an Active Record model, one record per role in a context. It lives in the engine's `app/models`, so Rails reloads it together with the app's models. Managing the roles themselves lives here; `Rabarber::RoleManagement` exposes it on the `Rabarber` module. `Rabarber::RoleAssignment` maps the table that assigns roles to users, so assignments can be added and removed in bulk.
- `Rabarber::Authorization`: the controller concern: declaring rules with `grant_access`, the check before each action, and what happens when access is denied.
- `Rabarber::Core::Permissions`: all the rules declared by the app's controllers, per controller and per action. `Rabarber::Core::Rule` is one rule: roles, context and dynamic conditions.
- `Rabarber::Core::Cache`: caches each user's roles per context.
- `Rabarber::Helpers`: the view helpers.
- `Rabarber::Inputs`: check arguments and configuration values where they enter Rabarber, and raise Rabarber errors.
- `Rabarber::MigrationHelpers` and the generator: database setup and data migrations in the app.

The specs run against a dummy Rails app in `spec/support` that really boots, so the engine is tested the way it runs in an app.

## Invariants

- Rabarber does nothing at boot that can fail. The app and Rails commands always start, even when the user model or the roles tables don't exist yet; problems show up on use.
- An app has one user model.
- Access is denied unless a rule grants it. Rules only add access: any matching rule is enough, and controller-wide rules also apply to subclasses.
- Authorization always needs a user. When there is none, Rabarber raises an error instead of denying access.
- A role exists in exactly one context: global, a model class, or a model record. The same name in different contexts is a different role.

## Boundaries

- Rabarber does authorization only. Authentication stays in the app, and Rabarber gets the user from the app's controller.
- Rabarber doesn't know how the app's cache is set up or shared between processes. Where its own methods can't keep the cache correct, as with the context migrations, the README tells the app to clear it.

## Coding rules

- No defensive programming. Establish the contract and the states the code can actually be in, then write for those. Arguments are checked once, where they enter Rabarber; the code inside trusts them. When the contract is unclear, find out or ask instead of handling states that may never happen.
- No workarounds. Use only the documented public interface of Rails and every other dependency. When something doesn't work, isn't meant to be used that way, or can't do what's needed, stop and say so: it may mean the approach is wrong.
- Specs test behavior through the public interface, not implementation details. Don't add specs that only repeat another.

## Unfinished work

- TODO comments mark what is still left in the current branch. CI fails on them, so nothing can be released while any remain.
