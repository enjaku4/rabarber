# Rabarber: Simplified Authorization for Rails

[![Gem Version](https://badge.fury.io/rb/rabarber.svg)](http://badge.fury.io/rb/rabarber)
[![Github Actions badge](https://github.com/enjaku4/rabarber/actions/workflows/ci.yml/badge.svg)](https://github.com/enjaku4/rabarber/actions/workflows/ci.yml)

Rabarber is a role-based authorization library for Ruby on Rails. It provides a set of tools for managing user roles and defining authorization rules, supports multi-tenancy and comes with audit logging for enhanced security.

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
  - [Context / Multi-tenancy](#context--multi-tenancy)
  - [When Unauthorized](#when-unauthorized)
  - [Skip Authorization](#skip-authorization)
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

**`#assign_roles(*roles, context: nil, create_new: true)`**

To assign roles, use:

```rb
user.assign_roles(:accountant, :marketer)
```
By default, it will automatically create any roles that don't exist. If you want to assign only existing roles and prevent the creation of new ones, use the method with `create_new: false` argument:
```rb
user.assign_roles(:accountant, :marketer, create_new: false)
```
The method returns an array of roles assigned to the user.

**`#revoke_roles(*roles, context: nil)`**

To revoke roles, use:

```rb
user.revoke_roles(:accountant, :marketer)
```
If the user doesn't have the role you want to revoke, it will be ignored.

The method returns an array of roles assigned to the user.

**`#has_role?(*roles, context: nil)`**

To check whether the user has a role, use:

```rb
user.has_role?(:accountant, :marketer)
```

It returns `true` if the user has at least one role and `false` otherwise.

**`#roles(context: nil)`**

To get the list of roles assigned to the user, use:

```rb
user.roles
```

**`#all_roles`**

To get all roles assigned to the user, grouped by context, use:

```rb
user.all_roles
```

---

To manipulate roles directly, you can use `Rabarber::Role` methods:

**`.add(role_name, context: nil)`**

To add a new role, use:

```rb
Rabarber::Role.add(:admin)
```

This will create a new role with the specified name and return `true`. If the role already exists, it will return `false`.

**`.rename(old_role_name, new_role_name, context: nil, force: false)`**

To rename a role, use:

```rb
Rabarber::Role.rename(:admin, :administrator)
```
The first argument is the old name, and the second argument is the new name. This will rename the role and return `true`. If the role with a new name already exists, it will return `false`.

The method won't rename the role and will return `false` if it is assigned to any user. To force the rename, use the method with `force: true` argument:
```rb
Rabarber::Role.rename(:admin, :administrator, force: true)
```

**`.remove(role_name, context: nil, force: false)`**

To remove a role, use:

```rb
Rabarber::Role.remove(:admin)
```

This will remove the role and return `true`. If the role doesn't exist, it will return `false`.

The method won't remove the role and will return `false` if it is assigned to any user. To force the removal, use the method with `force: true` argument:
```rb
Rabarber::Role.remove(:admin, force: true)
```

**`.names(context: nil)`**

If you need to list the roles available in your application, use:

```rb
Rabarber::Role.names
```

**`.all_names`**

If you need list all roles available in your application, grouped by context, use:

```rb
Rabarber::Role.all_names
```

**`.assignees(role_name, context: nil)`**

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
This adds `.grant_access(action: nil, roles: nil, context: nil, if: nil, unless: nil)` method which allows you to define the authorization rules.

The most basic usage of the method is as follows:

```rb
module Crm
  class InvoicesController < ApplicationController
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
end
```
This grants access to `index` action for users with `accountant` or `admin` role, and access to `destroy` action for `admin` users only.

You can also define controller-wide rules (without `action` argument):

```rb
module Crm
  class BaseController < ApplicationController
    grant_access roles: [:admin, :manager]

    grant_access action: :dashboard, roles: :marketer
    def dashboard
      # ...
    end
  end
end

module Crm
  class InvoicesController < Crm::BaseController
    grant_access roles: :accountant
    def index
      # ...
    end

    def delete
      # ...
    end
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

This allows everyone to access `OrdersController` and its children and also `index` action in `InvoicesController`.

If you've set `must_have_roles` setting to `true`, then only the users with at least one role can gain access. This setting can be useful if your requirements are such that users without roles are not allowed to access anything.

Also keep in mind that rules defined in child classes don't override parent rules but rather add to them:
```rb
module Crm
  class BaseController < ApplicationController
    grant_access roles: :admin
  # ...
  end
end

module Crm
  class InvoicesController < Crm::BaseController
    grant_access roles: :accountant
  # ...
  end
end
```
This means that `Crm::InvoicesController` is still accessible to `admin` but is also accessible to `accountant`.

This applies as well to multiple rules defined for the same controller or action:
```rb
module Crm
  class OrdersController < ApplicationController
    grant_access roles: :manager, context: Order
    grant_access roles: :admin

    grant_access action: :show, roles: :client, context: -> { Order.find(params[:id]) }
    grant_access action: :show, roles: :accountant
    def show
      # ...
    end
  end
end
```
This will add rules for `manager` and `admin` roles for all actions in `Crm::OrdersController`, and for `client` and `accountant` roles for the `show` action.

## Dynamic Authorization Rules

For more complex cases, Rabarber provides dynamic rules:

```rb
module Crm
  class OrdersController < ApplicationController
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
end

module Crm
  class InvoicesController < ApplicationController
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
end
```
You can pass a dynamic rule as `if` or `unless` argument. It can be a symbol, in which case the method with that name will be called, or alternatively it can be a proc that will be executed within the context of the controller instance at request time.

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

## Context / Multi-tenancy

Rabarber supports multi-tenancy by providing a context feature. This allows you to define and authorize roles and rules within a specific context.

Every Rabarber method can accept a context as an additional keyword argument. By default, the context is set to `nil`, meaning the roles are global. Thus, all examples from other sections of this README are valid for global roles. Apart from being global, the context can be an instance of ActiveRecord model or a class.

E.g., consider a model named `Project`, where each project has its owner and regular members. Roles can be defined like this:

```rb
user.assign_roles(:owner, context: project)
another_user.assign_roles(:member, context: project)
```

Then the roles can be verified:

```rb
user.has_role?(:owner, context: project)
another_user.has_role?(:member, context: project)
```

A role can also be added using a class as a context, e.g., for project admins who can manage all projects:

```rb
user.assign_roles(:admin, context: Project)
```

And then it can also be verified:

```rb
user.has_role?(:admin, context: Project)
```

In authorization rules, the context can be used in the same way, but it also can be a proc or a symbol (similar to dynamic rules):

```rb
class ProjectsController < ApplicationController
  grant_access roles: :admin, context: Project

  grant_access action: :show, roles: :member, context: :project
  def show
    # ...
  end

  grant_access action: :update, roles: :owner, context: -> { Project.find(params[:id]) }
  def update
    # ...
  end

  private

  def project
    Project.find(params[:id])
  end
end
```

It's important to note that role names are not unique globally but are unique within the scope of their context. E.g., `user.assign_roles(:admin, context: Project)` and `user.assign_roles(:admin)` assign different roles to the user. The same as `Rabarber::Role.add(:admin, context: Project)` and `Rabarber::Role.add(:admin)` create different roles.

If you want to see all the roles assigned to a user within a specific context, you can use:

```rb
user.roles(context: project)
```

Or if you want to get all the roles available in a specific context, you can use:

```rb
Rabarber::Role.names(context: Project)
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

## Skip Authorization

To skip authorization, use `.skip_authorization(options = {})` method:

```rb
class TicketsController < ApplicationController
  skip_authorization only: :index
  # ...
end
```

This method accepts the same options as `skip_before_action` method in Rails.

## View Helpers

Rabarber also provides a couple of helpers that can be used in views: `visible_to(*roles, context: nil, &block)` and `hidden_from(*roles, context: nil, &block)`. To use them, simply include `Rabarber::Helpers` in the desired helper. Usually it is `ApplicationHelper`, but it can be any helper of your choice.

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
