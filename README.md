# Rabarber: Simplified Authorization for Rails

[![Gem Version](https://badge.fury.io/rb/rabarber.svg)](http://badge.fury.io/rb/rabarber)
[![Github Actions badge](https://github.com/enjaku4/rabarber/actions/workflows/ci.yml/badge.svg)](https://github.com/enjaku4/rabarber/actions/workflows/ci.yml)

Rabarber is an authorization library for Ruby on Rails, primarily designed for use in the web layer of your application but not limited to that. It provides a set of useful tools for managing user roles and defining authorization rules.

---

#### Example of Usage:

Consider a CRM where users with different roles have distinct access levels. For instance, the role 'accountant' can interact with invoices but cannot access marketing information, while the role 'marketer' has access to marketing-related data. Such authorization rules can be easily defined with Rabarber.

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

Next, generate a migration to create tables for storing roles in the database:

```
rails g rabarber:roles
```

This will create a migration file in `db/migrate` directory.

Replace `raise(Rabarber::Error, "Please specify your user model's table name")` in that file with the name of your user model's table.

Finally, run the migration to apply the changes to the database:

```
rails db:migrate
```

## Configuration

Rabarber can be configured by adding the following code into an initializer:

```rb
Rabarber.configure do |config|
  config.current_user_method = :authenticated_user
  config.must_have_roles = true
  config.when_unauthorized = ->(controller) {
    controller.head 418
  }
end
```
- `current_user_method` must be a symbol representing the method that returns the currently authenticated user. The default value is `:current_user`.
- `must_have_roles` must be a boolean determining whether a user with no roles can access endpoints permitted to everyone. The default value is `false` (allowing users without roles to access endpoints permitted to everyone).
- `when_unauthorized` must be a lambda where you can define your actions when access is not authorized (`controller` is an instance of the controller where the code is executed). By default, the user is redirected back if the request format is HTML; otherwise, a 401 Unauthorized response is sent.

## Usage

Include `Rabarber::HasRoles` module in your model representing users in your application:

```rb
class User < ApplicationRecord
  include Rabarber::HasRoles
  ...
end
```

### This adds the following methods:

#### `#assign_roles`

To assign roles to the user, use:

```rb
user.assign_roles(:accountant, :marketer)
```
By default, `#assign_roles` method will automatically create any roles that don't exist. If you want to assign only existing roles and prevent the creation of new ones, use the method with `create_new: false` argument:
```rb
user.assign_roles(:accountant, :marketer, create_new: false)
```

You can also explicitly create new roles simply by using:

```rb
Rabarber::Role.create(name: "manager")
```
The role names are unique.

#### `#revoke_roles`

To revoke roles, use:

```rb
user.revoke_roles(:accountant, :marketer)
```
If any of the specified roles doesn't exist or the user doesn't have the role you want to revoke, it will be ignored.

#### `#has_role?`

To check whether the user has a role, use:

```rb
user.has_role?(:accountant, :marketer)
```

It returns `true` if the user has at least one role and `false` otherwise.

#### `#roles`

To view all the roles assigned to the user, use:

```rb
user.roles
```

If you need to list all the role names available in your application, use:

```rb
Rabarber::Role.names
```

`Rabarber::Role` is a model that represents roles within your application. It has a single attribute, `name`, which is validated for both uniqueness and presence. You can treat `Rabarber::Role` as a regular Rails model and use Active Record methods on it if necessary.

Utilize the aforementioned methods to manipulate user roles. For example, create a custom UI for managing roles or assign necessary roles during migration or runtime (e.g., when the user is created). You can also write custom authorization policies based on `#has_role?` method (e.g., to scope the data that the user can access). Adapt these methods to fit the requirements of your application.

---

### Authorization Rules

Include `Rabarber::Authorization` module into the controller that needs authorization rules to be applied (authorization rules will be applied to the controller and its children). Typically, it is `ApplicationController`, but it can be any controller.

```rb
class ApplicationController < ActionController::Base
  include Rabarber::Authorization
  ...
end
```
This adds `.grant_access` method to the controller and its children. This method allows you to define the authorization rules.

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

This allows everyone to access `OrdersController` and its children and `index` action in `InvoicesController`.

If you've set `must_have_roles` setting to `true`, then, only the users with at least one role can have access. This setting can be useful if your requirements are such that users without roles are not allowed to see anything.

For more complex rules, Rabarber provides the following:

```rb
class OrdersController < ApplicationController
  grant_access if: :user_has_access?
  ...

  private

  def user_has_access?
    ...
  end
end

class InvoicesController < ApplicationController
  grant_access action: :index, roles: :accountant, if: -> { current_user.passed_probation_period? }
  def index
    ...
  end
end
```
You can pass a custom rule as `if` argument. It can be a symbol (the method with the same name will be called) or a lambda.

Rules defined in children don't override parent rules but rather add to them:
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

---

### View Helpers

Rabarber also provides a couple of helpers that can be used in views: `visible_to` and `hidden_from`. The usage is straightforward:

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

Encountered a bug or facing a problem?

- **Create an Issue**: If you've identified a problem or have a feature request, please create an issue on the gem's GitHub repository. Be sure to provide detailed information about the problem, including the steps to reproduce it.
- **Contribute a Solution**: Found a fix for the issue or want to contribute to the project? Feel free to create a pull request with your changes.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
