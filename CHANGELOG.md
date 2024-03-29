## 1.4.0

- Add 'Audit trail' feature: Logging of role assignments, revocations, and unauthorized access attempts
- Add `audit_trail_enabled` configuration option, allowing to enable or disable the audit trail
- Deprecate `when_actions_missing` and `when_roles_missing` configuration options (see [the discussion](https://github.com/enjaku4/rabarber/discussions/48))

## 1.3.1

- Add `Rabarber::Role.assignees_for` method
- Fix inconsistent behavior where passing `nil` as a role name to role management methods would raise an `ActiveRecord` error instead of `Rabarber` error
- Various minor code improvements

## 1.3.0

- Add methods to directly add, rename, and remove roles
- Modify `Rabarber::HasRoles#assign_roles` and `Rabarber::HasRoles#revoke_roles` methods to return the list of roles assigned to the user
- Minor performance improvements

## 1.2.2

- Refactor to improve readability and maintainability
- Fix minor code errors

## 1.2.1

- Cache roles to avoid unnecessary database queries
- Introduce `cache_enabled` configuration option allowing to enable or disable role caching
- Enhance the migration generator so that it can receive the table name of the model representing users in the application as an argument
- Fix an issue where an error would be raised if the user is not authenticated
- Various minor improvements

## 1.2.0

- Enhance handling of missing actions and roles specified in `grant_access` method by raising an error for missing actions and logging a warning for missing roles
- Introduce `when_actions_missing` and `when_roles_missing` configuration options, allowing to customize the behavior when actions or roles are not found

## 1.1.0

- Add support for `unless` argument in `grant_access` method, allowing to define negated dynamic rules
- Fix a bug where specifying a dynamic rule as a symbol without specifying an action would result in an error

## 1.0.5

- Add co-author: [trafium](https://github.com/trafium)

## 1.0.4

- Allow to use strings as role names

## 1.0.3

- Enhance clarity by improving error types and messages
- Resolve inconsistency in types of role names

## 1.0.2

- Various enhancements for gem development and release
- Modify `Rabarber::HasRoles#roles` method to return an array of role names instead of `Rabarber::Role` objects

## 1.0.1

- Various enhancements for gem development

## 1.0.0

- Drop support for Ruby 2.7
- Add support for Ruby 3.3
- Various minor improvements

## 0.1.5

- Add missing `foreign_key` option to `CreateRabarberRoles` migration
- Allow only lowercase alphanumeric characters and underscores in role names

## 0.1.4

- Remove `Rabarber::HasRoles#role?` method as unnecessary

## 0.1.3

- Fully revise and update README for clarity

## 0.1.2

- Fix check that `Rabarber::HasRoles` can only be included once

## 0.1.1

- Initial release
