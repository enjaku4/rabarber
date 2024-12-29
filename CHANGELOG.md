## v4.1.0

### Features:

- Added `Rabarber::Role.all_names` method to retrieve all roles available in the application, grouped by context
- Added `Rabarber::HasRoles#all_roles` method to retrieve all roles assigned to a user, grouped by context

### Bugs:

- Fixed potential bug in role revocation caused by checking for the presence of a role in the cache instead of the database

## v4.0.2

### Misc:

- Added support for Ruby 3.4
- Updated some error messages for clarity

## v4.0.1

### Bugs:

- Resolved an issue preventing Rabarber from being used with the RBS Rails gem

## v4.0.0

### Breaking:

- Dropped support for Ruby 3.0
- Dropped support for Rails 6.1

### Misc:

- Added support for Rails 8.0

## v3.0.2

### Misc:

- Improved performance for authorization checks
- Refactored codebase for better maintainability

## v3.0.1

### Misc:

- Added support for Rails 7.2
- Updated gemspec file to include missing metadata

## v3.0.0

### Breaking:

- Changed Rabarber roles table structure

To upgrade to v3.0.0, please refer to the [migration guide](https://github.com/enjaku4/rabarber/discussions/58)

### Features:

- Introduced the ability to define and authorize roles within a specific context

### Misc:

- Revised log messages in the audit trail for clarity and conciseness

## v2.1.0

### Features:

- Added `Rabarber::Authorization.skip_authorization` method to skip authorization checks

## v2.0.0

### Breaking:

- Removed `when_actions_missing` and `when_roles_missing` configuration options
- Replaced `when_unauthorized` configuration option with an overridable controller method
- Renamed `Rabarber::Role.assignees_for` method to `Rabarber::Role.assignees`

To upgrade to v2.0.0, please refer to the [migration guide](https://github.com/enjaku4/rabarber/discussions/52)

### Features:

- Added support for UUID primary keys

### Bugs:

- Fixed the issue where an error would occur when using view helpers if the user was not authenticated

### Misc:

- Significant refactoring and code improvements

## v1.4.1

- Fix an issue where an error could be raised when using controller-wide dynamic rules

## v1.4.0

- Add 'Audit trail' feature: Logging of role assignments, revocations, and unauthorized access attempts
- Add `audit_trail_enabled` configuration option, allowing to enable or disable the audit trail
- Deprecate `when_actions_missing` and `when_roles_missing` configuration options (see [the discussion](https://github.com/enjaku4/rabarber/discussions/48))

## v1.3.1

- Add `Rabarber::Role.assignees_for` method
- Fix inconsistent behavior where passing `nil` as a role name to role management methods would raise an `ActiveRecord` error instead of `Rabarber` error
- Various minor code improvements

## v1.3.0

- Add methods to directly add, rename, and remove roles
- Modify `Rabarber::HasRoles#assign_roles` and `Rabarber::HasRoles#revoke_roles` methods to return the list of roles assigned to the user
- Minor performance improvements

## v1.2.2

- Refactor to improve readability and maintainability
- Fix minor code errors

## v1.2.1

- Cache roles to avoid unnecessary database queries
- Introduce `cache_enabled` configuration option allowing to enable or disable role caching
- Enhance the migration generator so that it can receive the table name of the model representing users in the application as an argument
- Fix an issue where an error would be raised if the user is not authenticated
- Various minor improvements

## v1.2.0

- Enhance handling of missing actions and roles specified in `grant_access` method by raising an error for missing actions and logging a warning for missing roles
- Introduce `when_actions_missing` and `when_roles_missing` configuration options, allowing to customize the behavior when actions or roles are not found

## v1.1.0

- Add support for `unless` argument in `grant_access` method, allowing to define negated dynamic rules
- Fix a bug where specifying a dynamic rule as a symbol without specifying an action would result in an error

## v1.0.5

- Add co-author: [trafium](https://github.com/trafium)

## v1.0.4

- Allow to use strings as role names

## v1.0.3

- Enhance clarity by improving error types and messages
- Resolve inconsistency in types of role names

## v1.0.2

- Various enhancements for gem development and release
- Modify `Rabarber::HasRoles#roles` method to return an array of role names instead of `Rabarber::Role` objects

## v1.0.1

- Various enhancements for gem development

## v1.0.0

- Drop support for Ruby 2.7
- Add support for Ruby 3.3
- Various minor improvements

## v0.1.5

- Add missing `foreign_key` option to `CreateRabarberRoles` migration
- Allow only lowercase alphanumeric characters and underscores in role names

## v0.1.4

- Remove `Rabarber::HasRoles#role?` method as unnecessary

## v0.1.3

- Fully revise and update README for clarity

## v0.1.2

- Fix check that `Rabarber::HasRoles` can only be included once

## v0.1.1

- Initial release
