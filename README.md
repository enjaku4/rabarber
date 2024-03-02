<!-- TODO -->

# Rabarber: Simplified Authorization for Rails

[![Gem Version](https://badge.fury.io/rb/rabarber.svg)](http://badge.fury.io/rb/rabarber)
[![Github Actions badge](https://github.com/enjaku4/rabarber/actions/workflows/ci.yml/badge.svg)](https://github.com/enjaku4/rabarber/actions/workflows/ci.yml)

Rabarber is a role-based authorization library for Ruby on Rails, designed primarily for use in the application's web layer (specifically controllers and views) but not limited to that. It provides tools for managing user roles and defining authorization rules, mainly focusing on answering the question of 'Who can access which endpoint?'.

Unlike some other libraries, Rabarber does not handle data scoping. Instead, it focuses on providing a lightweight and flexible solution for role-based access control, allowing developers to implement data scoping according to their specific business rules within their application's logic.

---

**Example of Usage**:

Consider a CRM where users with different roles have distinct access levels. For instance, the role `accountant` can interact with invoices but cannot access marketing information, while the role `marketer` has access to marketing-related data. Such authorization rules can be easily defined with Rabarber.

---

And this is how your controller might look with Rabarber:

```rb
class TicketsController < ApplicationController
  grant_access roles: :admin

  grant_access action: :index, roles: :manager
  def index
    ...
  end

  def delete
    ...
  end
end
```
This means that `admin` users can access everything in `TicketsController`, while `manager` role can access only `index` action.

## Installation

Add the Rabarber gem to your Gemfile:

```
gem "rabarber"
```

Install the gem:

```
bundle install
```

Next, generate a migration to create tables for storing roles in the database. Make sure to specify the table name of the model representing users in your application as an argument. For instance, if the table name is `users`, run:

```
rails g rabarber:roles users
```

Finally, run the migration to apply the changes to the database:

```
rails db:migrate
```

## Configuration

If specific customization is required, Rabarber can be configured by using `.configure` method in an initializer:

```rb
Rabarber.configure do |config|
  config.cache_enabled = true
  config.current_user_method = :current_user
  config.must_have_roles = false
  config.when_actions_missing = -> (missing_actions, context) { ... }
  config.when_roles_missing = -> (missing_roles, context) { ... }
  config.when_unauthorized = -> (controller) { ... }
end
```

- `cache_enabled` must be a boolean determining whether roles are cached. _Roles are cached by default to avoid unnecessary database queries._ If you want to disable caching, set this option to `false`. If caching is enabled and you need to clear the cache, use `Rabarber::Cache.clear` method.

- `current_user_method` must be a symbol representing the method that returns the currently authenticated user. _The default value is `:current_user`._

- `must_have_roles` must be a boolean determining whether a user with no roles can access endpoints permitted to everyone. _The default value is `false` (allowing users without roles to access endpoints permitted to everyone)._

- `when_actions_missing` must be a proc where you can define the behaviour when the actions specified in `grant_access` method cannot be found in the controller (`missing_actions` is an array of symbols e.g., `[:index]`, `context` is a hash that looks like this: `{ controller: "InvoicesController" }`). This check is performed on every request and when the application is initialized if `eager_load` configuration is enabled in Rails. _By default, an error is raised when actions are missing._

- `when_roles_missing` must be a proc where you can define the behaviour when the roles specified in `grant_access` method cannot be found in the database (`missing_roles` is an array of symbols e.g., `[:admin]`, `context` is a hash that looks like this: `{ controller: "InvoicesController", action: "index" }`). This check is performed on every request and when the application is initialized if `eager_load` configuration is enabled in Rails. _By default, only a warning is logged when roles are missing._

- `when_unauthorized` must be a proc where you can define the behaviour when access is not authorized (`controller` is an instance of the controller where the code is executed). _By default, the user is redirected back if the request format is HTML; otherwise, a 401 Unauthorized response is sent._

## Roles

Include `Rabarber::HasRoles` module in your model representing users in your application:

```rb
class User < ApplicationRecord
  include Rabarber::HasRoles
  ...
end
```

This adds the following methods:

**`#assign_roles`**

To assign roles, use:

```rb
user.assign_roles(:accountant, :marketer)
```
By default, `#assign_roles` method will automatically create any roles that don't exist. If you want to assign only existing roles and prevent the creation of new ones, use the method with `create_new: false` argument:
```rb
user.assign_roles(:accountant, :marketer, create_new: false)
```
The method returns an array of roles assigned to the user.

**`#revoke_roles`**

To revoke roles, use:

```rb
user.revoke_roles(:accountant, :marketer)
```
If any of the specified roles doesn't exist or the user doesn't have the role you want to revoke, it will be ignored.

The method returns an array of roles assigned to the user.

**`#has_role?`**

To check whether the user has a role, use:

```rb
user.has_role?(:accountant, :marketer)
```

It returns `true` if the user has at least one role and `false` otherwise.

**`#roles`**

To view all the roles assigned to the user, use:

```rb
user.roles
```

---

To manipulate roles directly, you can use `Rabarber::Role` methods:

**`.add`**

To add a new role, use:

```rb
Rabarber::Role.add(:admin)
```

This will create a new role with the specified name and return `true`. If the role already exists, it will return `false`.

**`.rename`**

To rename a role, use:

```rb
Rabarber::Role.rename(:admin, :administrator)
```
The first argument is the old name, and the second argument is the new name. This will rename the role and return `true`. If a role with the new name already exists, it will return `false`.

The method won't rename the role and will return `false` if it is assigned to any user. To force the rename, use the method with `force: true` argument:
```rb
Rabarber::Role.rename(:admin, :administrator, force: true)
```

**`.remove`**

To remove a role, use:

```rb
Rabarber::Role.remove(:admin)
```

This will remove the role and return `true`. If the role doesn't exist, it will return `false`.

The method won't remove the role and will return `false` if it is assigned to any user. To force the removal, use the method with `force: true` argument:
```rb
Rabarber::Role.remove(:admin, force: true)
```

**`.names`**

If you need to list all the role names available in your application, use:

```rb
Rabarber::Role.names
```

## Authorization Rules

Include `Rabarber::Authorization` module into the controller that needs authorization rules to be applied. Typically, it is `ApplicationController`, but it can be any controller of your choice.

```rb
class ApplicationController < ActionController::Base
  include Rabarber::Authorization
  ...
end
```
This adds `.grant_access` method which allows you to define the authorization rules.

The most basic usage of the method is as follows:

```rb
class InvoicesController < ApplicationController
  grant_access action: :index, roles: [:accountant, :admin]
  def index
    ...
  end

  grant_access action: :delete, roles: :admin
  def delete
    ...
  end
end
```
This grants access to `index` action for users with `accountant` or `admin` role, and access to `delete` action for `admin` users only.

You can also define controller-wide rules (without `action` argument):

```rb
class Crm::BaseController < ApplicationController
  grant_access roles: [:admin, :manager]

  grant_access action: :dashboard, roles: :marketer
  def dashboard
    ...
  end
end

class Crm::InvoicesController < Crm::BaseController
  grant_access roles: :accountant
  def index
    ...
  end

  def delete
    ...
  end
end
```
This means that `admin` and `manager` have access to all the actions inside `Crm::BaseController` and its children, while `accountant` role has access only to the actions in `Crm::InvoicesController` and its possible children. Users with `marketer` role can only see the dashboard in this example.

Roles can also be omitted:

```rb
class OrdersController < ApplicationController
  grant_access
  ...
end

class InvoicesController < ApplicationController
  grant_access action: :index
  def index
    ...
  end
end
```

This allows everyone to access `OrdersController` and its children and also `index` action in `InvoicesController`. This extends to scenarios where there is no user present, i.e. when the method responsible for returning the currently authenticated user in your application returns `nil`.

_Be aware that if the user is not authenticated (the method responsible for returning the currently authenticated user in your application returns `nil`), Rabarber will treat this situation as if the user with no roles assigned was authenticated._

If you've set `must_have_roles` setting to `true`, then, only the users with at least one role can have access. This setting can be useful if your requirements are such that users without roles are not allowed to access anything.

For more complex cases, Rabarber provides dynamic rules:

```rb
class OrdersController < ApplicationController
  grant_access if: :current_company_accountant?
  grant_access unless: :fired?
  ...

  private

  def current_company_accountant?
    current_company.accountant == current_user
  end

  def fired?
    current_user.fired?
  end
end

class InvoicesController < ApplicationController
  grant_access action: :index, roles: :accountant, if: -> { current_user.passed_probation_period? }
  def index
    ...
  end

  grant_access action: :show, roles: :client, unless: -> { current_user.banned? }
  def show
    ...
  end
end
```
You can pass a dynamic rule as `if` or `unless` argument. It can be a symbol, in which case the method with the same name will be called. Alternatively, it can be a proc, which will be executed within the context of the controller's instance.

Rules defined in child classes don't override parent rules but rather add to them:
```rb
class Crm::BaseController < ApplicationController
  grant_access roles: :admin
  ...
end

class Crm::InvoicesController < Crm::BaseController
  grant_access roles: :accountant
  ...
end
```
This means that `Crm::InvoicesController` is still accessible to `admin` but is also accessible to `accountant`.

## View Helpers

Rabarber also provides a couple of helpers that can be used in views: `visible_to` and `hidden_from`. To use them, simply include `Rabarber::Helpers` in the desired helper. Usually it is `ApplicationHelper`, but it can be any helper of your choice.

```rb
module ApplicationHelper
  include Rabarber::Helpers
  ...
end
```

The usage is straightforward:

```erb
<%= visible_to(:admin, :manager) do %>
  <p>Visible only to admins and managers</p>
<% end %>
```

```erb
<%= hidden_from(:accountant) do %>
  <p>Accountant cannot see this</p>
<% end %>
```

## Problems?

Facing a problem or want to suggest an enhancement?

- **Open a Discussion**: If you have a question, experience difficulties using the gem, or have an improvement suggestion, feel free to use the Discussions section.

Encountered a bug?

- **Create an Issue**: If you've identified a bug, please create an issue. Be sure to provide detailed information about the problem, including the steps to reproduce it.
- **Contribute a Solution**: Found a fix for the issue? Feel free to create a pull request with your changes.

## Contributing

Before opening an issue or creating a pull request, please read the [contributing guidelines](https://github.com/enjaku4/rabarber/blob/main/CONTRIBUTING.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rabarber project is expected to follow the [code of conduct](https://github.com/enjaku4/rabarber/blob/main/CODE_OF_CONDUCT.md).
