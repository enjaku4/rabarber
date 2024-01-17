## 1.1.0

- Add support for `unless` argument in `grant_access` method, allowing to define negated dynamic rules
- Fix a bug where specifying a dynamic rule as a symbol would cause an error when the action was not specified

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
