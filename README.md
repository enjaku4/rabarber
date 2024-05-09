<!-- TODO: describe context feature -->
<!-- TODO: explain that virtually every method is able to receive context -->

# Rabarber: Simplified Authorization for Rails

[![Gem Version](https://badge.fury.io/rb/rabarber.svg)](http://badge.fury.io/rb/rabarber)
[![Github Actions badge](https://github.com/enjaku4/rabarber/actions/workflows/ci.yml/badge.svg)](https://github.com/enjaku4/rabarber/actions/workflows/ci.yml)

Rabarber is a role-based authorization library for Ruby on Rails, primarily designed for use in the web layer of your application but not limited to that. It provides a set of tools for managing user roles and defining authorization rules, along with audit logging for enhanced security.

---

**Example of Usage**:

Consider a CRM system where users with different roles have distinct access levels. For instance, the role `accountant` can interact with invoices but cannot access marketing information, while the role `marketer` has access to marketing-related data. Such authorization rules can be easily defined with Rabarber.

---

And this is how your controller might look with Rabarber:

```rb
class TicketsController < ApplicationController
  grant_access roles: :admin

  grant_access action: :index, roles: :manager
  def index
    # ...
  end

  def delete
    # ...
  end
end
```
This means that `admin` users can access everything in `TicketsController`, while `manager` role can access only `index` action.

## Table of Contents

**Gem usage:**
  - [Installation](#installation)
  - [Configuration](#configuration)
  - [Roles](#roles)
  - [Authorization Rules](#authorization-rules)
  - [Dynamic Authorization Rules](#dynamic-authorization-rules)
  - [When Unauthorized](#when-unauthorized)
  - [View Helpers](#view-helpers)
  - [Audit Trail](#audit-trail)

**Community Resources:**
  - [Problems?](#problems)
  - [Contributing](#contributing)
  - [Code of Conduct](#code-of-conduct)

**Legal:**
  - [License](#license)

## Installation

Add the Rabarber gem to your Gemfile:

```rb
gem "rabarber"
```

Install the gem:

```shell
bundle install
```

Next, generate a migration to create tables for storing roles in the database. Make sure to specify the table name of the model representing users in your application as an argument. For instance, if the table name is `users`, run:

```shell
rails g rabarber:roles users
```

Rabarber supports UUIDs as primary keys. If your application uses UUIDs, add `--uuid` option to the generator:

```shell
rails g rabarber:roles users --uuid
```

Finally, run the migration to apply the changes to the database:

```shell
rails db:migrate
```

## Configuration

If specific customization is required, Rabarber can be configured by using `.configure` method in an initializer:

```rb
Rabarber.configure do |config|
  config.audit_trail_enabled = true
  config.cache_enabled = true
  config.current_user_method = :current_user
  config.must_have_roles = false
end
```

- `audit_trail_enabled` determines whether the audit trail functionality is enabled. The audit trail is enabled by default.
- `cache_enabled` determines whether roles are cached to avoid unnecessary database queries. Roles are cached by default. If you need to clear the cache, use `Rabarber::Cache.clear` method.
- `current_user_method` represents the method that returns the currently authenticated user. The default value is `:current_user`.
- `must_have_roles` determines whether a user with no roles can access endpoints permitted to everyone. The default value is `false` (allowing users without roles to access such endpoints).

## Roles

Include `Rabarber::HasRoles` module in your model representing users in your application:

```rb
class User < ApplicationRecord
  include Rabarber::HasRoles
  # ...
end
```

This adds the following methods:

**`#assign_roles(*roles, create_new: true)`**

To assign roles, use:

```rb
user.assign_roles(:accountant, :marketer)
```
By default, it will automatically create any roles that don't exist. If you want to assign only existing roles and prevent the creation of new ones, use the method with `create_new: false` argument:
```rb
user.assign_roles(:accountant, :marketer, create_new: false)
```
The method returns an array of roles assigned to the user.

**`#revoke_roles(*roles)`**

To revoke roles, use:

```rb
user.revoke_roles(:accountant, :marketer)
```
If the user doesn't have the role you want to revoke, it will be ignored.

The method returns an array of roles assigned to the user.

**`#has_role?(*roles)`**

To check whether the user has a role, use:

```rb
user.has_role?(:accountant, :marketer)
```

It returns `true` if the user has at least one role and `false` otherwise.

**`#roles`**

To get all the roles assigned to the user, use:

```rb
user.roles
```

---

To manipulate roles directly, you can use `Rabarber::Role` methods:

**`.add(role_name)`**

To add a new role, use:

```rb
Rabarber::Role.add(:admin)
```

This will create a new role with the specified name and return `true`. If the role already exists, it will return `false`.

**`.rename(old_role_name, new_role_name, force: false)`**

To rename a role, use:

```rb
Rabarber::Role.rename(:admin, :administrator)
```
The first argument is the old name, and the second argument is the new name. This will rename the role and return `true`. If the role with a new name already exists, it will return `false`.

The method won't rename the role and will return `false` if it is assigned to any user. To force the rename, use the method with `force: true` argument:
```rb
Rabarber::Role.rename(:admin, :administrator, force: true)
```

**`.remove(role_name, force: false)`**

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

**`.assignees(role_name)`**

To get all the users to whom the role is assigned, use:

```rb
Rabarber::Role.assignees(:admin)
```

## Authorization Rules

Include `Rabarber::Authorization` module into the controller that needs authorization rules to be applied. Typically, it is `ApplicationController`, but it can be any controller of your choice.

```rb
class ApplicationController < ActionController::Base
  include Rabarber::Authorization
  # ...
end
```
This adds `.grant_access(action: nil, roles: nil, if: nil, unless: nil)` method which allows you to define the authorization rules.

The most basic usage of the method is as follows:

```rb
class Crm::InvoicesController < ApplicationController
  grant_access action: :index, roles: [:accountant, :admin]
  def index
    @invoices = Invoice.all
    @invoices = @invoices.paid if current_user.has_role?(:accountant)
    # ...
  end

  grant_access action: :destroy, roles: :admin
  def destroy
    # ...
  end
end
```
This grants access to `index` action for users with `accountant` or `admin` role, and access to `destroy` action for `admin` users only.

_Note: Rabarber does not provide any built-in data scoping mechanism as it is not a part of the authorization layer and is not necessarily role specific or has anything to do with the current user. The business logic can vary drastically depending on the application, so you're encouraged to limit the data visibility yourself, for example, in the same way as in the example above, where `accountant` role can only see paid invoices._

You can also define controller-wide rules (without `action` argument):

```rb
class Crm::BaseController < ApplicationController
  grant_access roles: [:admin, :manager]

  grant_access action: :dashboard, roles: :marketer
  def dashboard
    # ...
  end
end

class Crm::InvoicesController < Crm::BaseController
  grant_access roles: :accountant
  def index
    # ...
  end

  def delete
    # ...
  end
end
```
This means that `admin` and `manager` have access to all the actions inside `Crm::BaseController` and its children, while `accountant` role has access only to the actions in `Crm::InvoicesController` and its possible children. Users with `marketer` role can only see the dashboard in this example.

Roles can also be omitted:

```rb
class OrdersController < ApplicationController
  grant_access
  # ...
end

class InvoicesController < ApplicationController
  grant_access action: :index
  def index
    # ...
  end
end
```

This allows everyone to access `OrdersController` and its children and also `index` action in `InvoicesController`. This extends to scenarios where there is no user present, i.e. when the method responsible for returning the currently authenticated user in your application returns `nil`.

_Note: If the user is not authenticated (the method responsible for returning the currently authenticated user in your application returns `nil`), Rabarber will handle this situation as if the user has no roles. If you've set `must_have_roles` setting to `true`, then only the users with at least one role can gain access. This setting can be useful if your requirements are such that users without roles are not allowed to access anything._

Also keep in mind that rules defined in child classes don't override parent rules but rather add to them:
```rb
class Crm::BaseController < ApplicationController
  grant_access roles: :admin
  # ...
end

class Crm::InvoicesController < Crm::BaseController
  grant_access roles: :accountant
  # ...
end
```
This means that `Crm::InvoicesController` is still accessible to `admin` but is also accessible to `accountant`.

## Dynamic Authorization Rules

For more complex cases, Rabarber provides dynamic rules:

```rb
class Crm::OrdersController < ApplicationController
  grant_access roles: :manager, if: :company_manager?, unless: :fired?

  def index
    # ...
  end

  private

  def company_manager?
    Company.find(params[:company_id]).manager == current_user
  end

  def fired?
    current_user.fired?
  end
end

class Crm::InvoicesController < ApplicationController
  grant_access roles: :senior_accountant

  grant_access action: :index, roles: [:secretary, :accountant], if: -> { InvoicesPolicy.new(current_user).can_access?(:index) }
  def index
    @invoices = Invoice.all
    @invoices = @invoices.where("total < 10000") if current_user.has_role?(:accountant)
    @invoices = @invoices.unpaid if current_user.has_role?(:secretary)
    # ...
  end

  grant_access action: :show, roles: :accountant, unless: -> { Invoice.find(params[:id]).total > 10_000 }
  def show
    # ...
  end
end
```
You can pass a dynamic rule as `if` or `unless` argument. It can be a symbol, in which case the method with that name will be called. Alternatively, it can be a proc, which will be executed within the context of the controller's instance.

You can use only dynamic rules without specifying roles if that suits your needs:
```rb
class InvoicesController < ApplicationController
  grant_access action: :index, if: -> { current_user.company == Company.find(params[:company_id]) }
  def index
    # ...
  end
end
```
This basically allows you to use Rabarber as a policy-based authorization library by calling your own custom policy within a dynamic rule:
```rb
class InvoicesController < ApplicationController
  grant_access action: :index, if: -> { InvoicesPolicy.new(current_user).can_access?(:index) }
  def index
    # ...
  end
end
```

## When Unauthorized

By default, in the event of an unauthorized attempt, Rabarber redirects the user back if the request format is HTML (with fallback to the root path), and returns a 401 (Unauthorized) status code otherwise.

This behavior can be customized by overriding private `when_unauthorized` method:

```rb
class ApplicationController < ActionController::Base
  include Rabarber::Authorization

  # ...

  private

  def when_unauthorized
    head :not_found # pretend the page doesn't exist
  end
end
```

The method can be overridden in different controllers, providing flexibility in handling unauthorized access attempts.

## View Helpers

Rabarber also provides a couple of helpers that can be used in views: `visible_to(*roles, &block)` and `hidden_from(*roles, &block)`. To use them, simply include `Rabarber::Helpers` in the desired helper. Usually it is `ApplicationHelper`, but it can be any helper of your choice.

```rb
module ApplicationHelper
  include Rabarber::Helpers
  # ...
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

## Audit Trail

Rabarber supports audit trail, which provides a record of user access control activity. This feature logs the following events:

- Role assignments to users
- Role revocations from users
- Unauthorized access attempts

The logs are written to the file `log/rabarber_audit.log` unless the `audit_trail_enabled` configuration option is set to `false`.

## Problems?

Facing a problem or want to suggest an enhancement?

- **Open a Discussion**: If you have a question, experience difficulties using the gem, or have a suggestion for improvements, feel free to use the Discussions section.

Encountered a bug?

- **Create an Issue**: If you've identified a bug, please create an issue. Be sure to provide detailed information about the problem, including the steps to reproduce it.
- **Contribute a Solution**: Found a fix for the issue? Feel free to create a pull request with your changes.

## Contributing

Before creating an issue or a pull request, please read the [contributing guidelines](https://github.com/enjaku4/rabarber/blob/main/CONTRIBUTING.md).

## Code of Conduct

Everyone interacting in the Rabarber project is expected to follow the [code of conduct](https://github.com/enjaku4/rabarber/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/enjaku4/rabarber/blob/main/LICENSE.txt).
