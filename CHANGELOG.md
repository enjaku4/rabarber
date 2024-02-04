## 1.2.1

- Cache roles to avoid unnecessary database queries
- Introduce `cache_enabled` configuration option, allowing to enable or disable role caching
- Enhance migration generator to accept user model's table name as an argument

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
- Modify `HasRoles#roles` method to return an array of role names instead of `Rabarber::Role` objects

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

- Remove `HasRoles#role?` method as unnecessary

## 0.1.3

- Fully revise and update README for clarity

## 0.1.2

- Fix check that `Rabarber::HasRoles` can only be included once

## 0.1.1

- Initial release
