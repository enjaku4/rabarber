# Rabarber: Simplified Authorization for Rails

[![Gem Version](https://badge.fury.io/rb/rabarber.svg)](http://badge.fury.io/rb/rabarber)
[![Github Actions badge](https://github.com/brownboxdev/rabarber/actions/workflows/ci.yml/badge.svg)](https://github.com/brownboxdev/rabarber/actions/workflows/ci.yml)

Rabarber is a role-based authorization library for Ruby on Rails. It provides a set of tools for managing user roles and defining authorization rules, with support for multi-tenancy and fine-grained access control.

---

**Example of Usage**:

Consider a CRM system where users with different roles have distinct access levels. For instance, the role `accountant` can interact with invoices but cannot access marketing information, while the role `marketer` has access to marketing-related data. You can define such authorization rules easily with Rabarber.

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
  - [Role Assignments](#role-assignments)
  - [Role Management](#role-management)
  - [Authorization Rules](#authorization-rules)
  - [Dynamic Authorization Rules](#dynamic-authorization-rules)
  - [Context / Multi-tenancy](#context--multi-tenancy)
  - [When Unauthorized](#when-unauthorized)
  - [Skip Authorization](#skip-authorization)
  - [View Helpers](#view-helpers)

**Community Resources:**
  - [Problems?](#problems)
  - [Contributing](#contributing)
  - [Code of Conduct](#code-of-conduct)
  - [Old Versions](#old-versions)

**Legal:**
  - [License](#license)

## Installation

Add Rabarber to your Gemfile:

```rb
gem "rabarber"
```

Install the gem:

```shell
bundle install
```

Generate a migration to create tables for storing roles. Run the generator with the table name used by the model that represents users in your application. For example, if the table is `users`, run:

```shell
rails g rabarber:roles users
```

Rabarber supports UUIDs as primary keys. If your application uses UUIDs, add `--uuid` option:

```shell
rails g rabarber:roles users --uuid
```

Finally, run the migration:

```shell
rails db:migrate
```

## Configuration

If customization is required, Rabarber can be configured using `.configure` method in an initializer:

```rb
Rabarber.configure do |config|
  config.cache_enabled = true
  config.current_user_method = :current_user
  config.user_model_name = "User"
end
```

- `cache_enabled` determines whether roles are cached to avoid unnecessary database queries. Roles are cached by default. If you need to clear the cache, use `Rabarber::Cache.clear` method.
- `current_user_method` defines the method used to access the currently authenticated user. Default is `:current_user`.
- `user_model_name` sets the name of the model representing the user in your application. Default is `"User"`.

## Role Assignments

Rabarber automatically augments your user model (defined via `user_model_name` configuration) with role-related methods.

**`#assign_roles(*roles, context: nil, create_new: true)`**

To assign roles, use:

```rb
user.assign_roles(:accountant, :marketer)
```

By default, it will automatically create any roles that don't exist. To assign only existing roles and prevent automatic creation, pass `create_new: false`:

```rb
user.assign_roles(:accountant, :marketer, create_new: false)
```

The method returns an array of roles assigned to the user.

**`#revoke_roles(*roles, context: nil)`**

To revoke roles, use:

```rb
user.revoke_roles(:accountant, :marketer)
```

Roles the user doesn’t have are ignored.

The method returns an array of roles assigned to the user.

**`#has_role?(*roles, context: nil)`**

To check whether the user has a role, use:

```rb
user.has_role?(:accountant, :marketer)
```

It returns `true` if the user has at least one of the given roles.

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

**`.assignees(role_name, context: nil)`**

To get all the users to whom the role is assigned, use:

```rb
Rabarber::Role.assignees(:admin)
```

## Role Management

To manipulate roles directly, you can use the following methods:

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

The old role must exist. If it doesn’t, an error is raised. If a role with the new name already exists, the method returns `false` and the rename fails.

The rename also fails if the role is assigned to any user. To force it, use:

```rb
Rabarber::Role.rename(:admin, :administrator, force: true)
```

**`.remove(role_name, context: nil, force: false)`**

To remove a role, use:

```rb
Rabarber::Role.remove(:admin)
```

The old role must exist. If it doesn’t, an error is raised. The method returns `true` if successful.

If the role is assigned to any user, removal will fail. To force it, use:

```rb
Rabarber::Role.remove(:admin, force: true)
```

**`.names(context: nil)`**

If you need to list the roles available in your application, use:

```rb
Rabarber::Role.names
```

**`.all_names`**

If you need to list all roles available in your application, grouped by context, use:

```rb
Rabarber::Role.all_names
```

## Authorization Rules

Include `Rabarber::Authorization` module in the controller where you want to define authorization rules. Typically, it is `ApplicationController`, but it can be any controller of your choice. Then use `.with_authorization(options = {})` method, which accepts the same options as Rails’ `before_action`, allowing you to perform authorization checks selectively.

```rb
class ApplicationController < ActionController::Base
  include Rabarber::Authorization

  with_authorization

  # ...
end

class InvoicesController < ApplicationController
  with_authorization only: [:update, :destroy]

  # ...
end
```

You must ensure the user is authenticated before authorization checks are performed.

To define authorization rules, use `.grant_access(action: nil, roles: nil, context: nil, if: nil, unless: nil)` method.

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

In this example, `admin` and `manager` have access to all actions in `Crm::BaseController` and its descendants, while `accountant` role has access only to the actions in `Crm::InvoicesController`. Users with `marketer` role can only see the dashboard.

You can also omit roles to allow unrestricted access:

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

This allows everyone to access `OrdersController` and its descendants as well as `index` action in `InvoicesController`.

Rules defined in descendant classes don't override ancestor rules but rather add to them:

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

This also applies when defining multiple rules for the same controller or action:

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

For more complex scenarios, Rabarber supports dynamic authorization rules:

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

You can pass a dynamic rule as `if` or `unless` argument. You can pass a symbol (method name) or a proc. Symbols refer to instance methods, and procs are evaluated in the controller at request time.

You can use only dynamic rules without specifying roles if that suits your needs:

```rb
class InvoicesController < ApplicationController
  grant_access action: :index, if: -> { current_user.company == Company.find(params[:company_id]) }
  def index
    # ...
  end
end
```

This allows you to use Rabarber as a policy-based authorization library by calling your own custom policy within a dynamic rule:

```rb
class InvoicesController < ApplicationController
  grant_access action: :index, if: -> { InvoicesPolicy.new(current_user).can_access?(:index) }
  def index
    # ...
  end
end
```

## Context / Multi-tenancy

Rabarber supports multi-tenancy through its context feature. This allows you to define and authorize roles and rules within a specific context.

Every Rabarber method can accept a context as an additional keyword argument. By default, the context is set to `nil`, meaning the roles are global. Thus, all examples from other sections of this README are valid for global roles. Besides being global, context can also be an instance of an `ActiveRecord` model or a class.

E.g., consider a model named `Project`, where each project has its owner and regular members. Roles can be defined like this:

```rb
user.assign_roles(:owner, context: project)
another_user.assign_roles(:member, context: project)
```

You can then check roles like this:

```rb
user.has_role?(:owner, context: project)
another_user.has_role?(:member, context: project)
```

A role can also be added using a class as a context, e.g., for project admins who can manage all projects:

```rb
user.assign_roles(:admin, context: Project)
```

And to check it:

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

Role names are scoped by context, i.e. `admin` in a project is different from a global `admin`, or from an `admin` in another project.

If you want to see all the roles assigned to a user within a specific context, you can use:

```rb
user.roles(context: project)
```

Or if you want to get all the roles available in a specific context, you can use:

```rb
Rabarber::Role.names(context: Project)
```

If a context object (e.g., a project) is deleted, any roles tied to it automatically become irrelevant and are no longer returned by role queries. Rabarber treats them as orphaned and ignores them.

However, if a context class is renamed (e.g., `Project` becomes `Campaign`), an exception will be raised the next time Rabarber attempts to load roles for that class. This is to ensure you explicitly handle the migration, either by migrating existing roles to the new context or by cleaning up old data.

To help with such scenarios, Rabarber provides two helper methods that can be called in migrations:

- `migrate_authorization_context!(old_context, new_context)` - renames a context
- `delete_authorization_context!(context)` – removes roles tied to a deleted context

These are irreversible data migrations.

## When Unauthorized

By default, Rabarber redirects back on unauthorized access if the request format is HTML (falling back to the root path), and returns a 401 Unauthorized for other formats.

You can customize this behavior by overriding the private `when_unauthorized` method:

```rb
class ApplicationController < ActionController::Base
  include Rabarber::Authorization

  with_authorization

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

This method accepts the same options as Rails’ `skip_before_action`.

## View Helpers

Rabarber provides two helpers for use in views: `visible_to(*roles, context: nil, &block)` and `hidden_from(*roles, context: nil, &block)`. To enable them, include `Rabarber::Helpers` in your helper module, typically `ApplicationHelper`.

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

## Problems?

Facing a problem or want to suggest an enhancement?

- **Open a Discussion**: If you have a question, experience difficulties using the gem, or have a suggestion for improvements, feel free to use the Discussions section.

Encountered a bug?

- **Create an Issue**: If you've identified a bug, please create an issue. Be sure to provide detailed information about the problem, including the steps to reproduce it.
- **Contribute a Solution**: Found a fix for the issue? Feel free to create a pull request with your changes.

## Contributing

Before creating an issue or a pull request, please read the [contributing guidelines](https://github.com/brownboxdev/rabarber/blob/main/CONTRIBUTING.md).

## Code of Conduct

Everyone interacting in the Rabarber project is expected to follow the [code of conduct](https://github.com/brownboxdev/rabarber/blob/main/CODE_OF_CONDUCT.md).

## Old Versions

Only the latest major version is supported. Older versions are obsolete and not maintained, but their READMEs are available here for reference:

[v4.x.x](https://github.com/brownboxdev/rabarber/blob/9353e70281971154d5acd70693620197a132c543/README.md) | [v3.x.x](https://github.com/brownboxdev/rabarber/blob/3bb273de7e342004abc7ef07fa4d0a9a3ce3e249/README.md)
 | [v2.x.x](https://github.com/brownboxdev/rabarber/blob/875b357ea949404ddc3645ad66eddea7ed4e2ee4/README.md) | [v1.x.x](https://github.com/brownboxdev/rabarber/blob/b81428429404e197d70317b763e7b2a21e02c296/README.md)

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/brownboxdev/rabarber/blob/main/LICENSE.txt).
