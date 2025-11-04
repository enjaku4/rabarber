# Rabarber: Simple Role-Based Authorization for Rails

[![Gem Version](https://badge.fury.io/rb/rabarber.svg)](http://badge.fury.io/rb/rabarber)
[![Downloads](https://img.shields.io/gem/dt/rabarber.svg)](https://rubygems.org/gems/rabarber)
[![Github Actions badge](https://github.com/enjaku4/rabarber/actions/workflows/ci.yml/badge.svg)](https://github.com/enjaku4/rabarber/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/enjaku4/rabarber.svg)](LICENSE)

Rabarber is a role-based authorization library for Ruby on Rails. It provides a set of tools for managing user roles and defining access rules, with support for multi-tenancy through context.

**Example of Usage:**

Consider a CRM system where users with different roles have distinct access levels. For instance, the role `accountant` can access invoice data but not marketing information, while the role `analyst` can view marketing data but not detailed financial records. You can define such authorization rules easily with Rabarber.

___

And this is how your controller might look with Rabarber:

```rb
class TicketsController < ApplicationController
  grant_access roles: :admin

  grant_access action: :index, roles: :manager
  def index
    # ...
  end

  def destroy
    # ...
  end
end
```

This means that `admin` users can access everything in `TicketsController`, while the `manager` role can access only the `index` action.

## Table of Contents

**Gem Usage:**
  - [Installation](#installation)
  - [Configuration](#configuration)
  - [User Role Methods](#user-role-methods)
  - [Direct Role Management](#direct-role-management)
  - [Authorization](#authorization)
  - [Dynamic Authorization Rules](#dynamic-authorization-rules)
  - [When Unauthorized](#when-unauthorized)
  - [Context / Multi-tenancy](#context--multi-tenancy)
  - [View Helpers](#view-helpers)

**Community Resources:**
  - [Getting Help and Contributing](#getting-help-and-contributing)
  - [License](#license)
  - [Code of Conduct](#code-of-conduct)
  - [Old Versions](#old-versions)

## Installation

Add Rabarber to your Gemfile:

```rb
gem "rabarber"
```

Install the gem:

```shell
bundle install
```

Generate the migration to store roles (replace `users` with your table name if different):

```shell
# For standard integer IDs
rails generate rabarber:roles users

# For UUID primary keys
rails generate rabarber:roles users --uuid
```

Run the migration:

```shell
rails db:migrate
```

## Configuration

Create an initializer to customize Rabarber's behavior (optional):

```rb
Rabarber.configure do |config|
  config.cache_enabled = true                 # Enable/disable role caching (default: true)
  config.current_user_method = :current_user  # Method to access current user (default: :current_user)
  config.user_model_name = "User"             # User model name (default: "User")
end
```

Roles are cached by default for better performance. Clear the cache manually when needed:

```rb
Rabarber::Cache.clear
```

## User Role Methods

Your user model is automatically augmented with role management methods:

### Role Assignment

```rb
# Assign roles (creates roles if they don't exist)
user.assign_roles(:admin, :manager)

# Assign only existing roles (don't create new ones)
user.assign_roles(:accountant, :manager, create_new: false)

# Revoke specific roles
user.revoke_roles(:admin, :manager)

# Revoke all roles
user.revoke_all_roles
```

All role assignment methods return the list of roles currently assigned to the user.

### Role Queries

```rb
# Check if user has any of the specified roles
user.has_role?(:accountant, :manager)

# Get user's roles in the global context
user.roles

# Get all user's roles grouped by context
user.all_roles

# Get users with any of the specified roles
User.with_role(:admin, :manager)
```

## Direct Role Management

You can also manage roles directly:

```rb
# Create a new role
Rabarber.create_role(:admin) # => true if created, false if already exists

# Rename a role
Rabarber.rename_role(:admin, :administrator) # => true if renamed, false if new name exists or role is assigned
Rabarber.rename_role(:admin, :administrator, force: true) # Force rename even if role is assigned

# Remove a role
Rabarber.delete_role(:admin) # => true if deleted, false if role is assigned
Rabarber.delete_role(:admin, force: true) # Force deletion even if role is assigned

# List available roles in the global context
Rabarber.roles

# List all available roles grouped by context
Rabarber.all_roles
```

> **Note:** Some methods have been deprecated in favor of the new API shown above. Deprecated methods still work but will be removed in a future major version. See the [changelog](https://github.com/enjaku4/rabarber/blob/main/CHANGELOG.md#v520) for the complete list of deprecated methods and their replacements.

## Authorization

### Setup

Include `Rabarber::Authorization` module in your controllers and configure protection:

```rb
class ApplicationController < ActionController::Base
  include Rabarber::Authorization

  with_authorization # Enable authorization check for all actions in all controllers by default
end
```

You can also enable authorization checks selectively. Both `with_authorization` and `skip_authorization` work exactly the same as Rails' `before_action` and `skip_before_action` methods:

```rb
class TicketsController < ApplicationController
  skip_authorization only: [:index, :show] # Skip authorization for specific actions
end

class InvoicesController < ApplicationController
  with_authorization except: [:index] # Enable authorization for all actions except index
end
```

Authorization requires an authenticated user. Rabarber will raise an error if no user is found via the configured `current_user_method`. Ensure authentication happens before authorization, and use `with_authorization` and `skip_authorization` to control authorization checks.

### Authorization Rules

Define authorization rules using `grant_access`:

```rb
class TicketsController < ApplicationController
  # Controller-wide access
  grant_access roles: :admin

  # Action-specific access
  grant_access action: :index, roles: [:manager, :support]
  def index
    # Accessible to admin, manager, and support roles
  end

  def destroy
    # Accessible to admin role only
  end
end
```

### Additive Rules

Authorization rules are additive - they combine across inheritance chains and when defined multiple times for the same action:

```rb
class BaseController < ApplicationController
  grant_access roles: :admin # Admin can access everything
end

class InvoicesController < BaseController
  grant_access roles: :accountant # Accountant can also access InvoicesController (along with admin)

  grant_access action: :index, roles: :manager
  grant_access action: :index, roles: :supervisor
  def index
    # Index is accessible to admin, accountant, manager, and supervisor
  end
end
```

### Unrestricted Access

It's possible to omit roles to allow unrestricted access:

```rb
class UnrestrictedController < ApplicationController
  grant_access # Allow all users to access all actions
end

class MixedController < ApplicationController
  grant_access action: :index # Unrestricted index action
  def index
    # Accessible to all users
  end

  grant_access action: :show, roles: :member # Restricted show action
  def show
    # Accessible to members only
  end
end
```

## Dynamic Authorization Rules

For more complex scenarios, Rabarber supports dynamic authorization rules:

```rb
class OrdersController < ApplicationController
  # Method-based conditions
  grant_access roles: :manager, if: :company_manager?, unless: :suspended?

  # Proc-based conditions
  grant_access action: :show, roles: :client, if: -> { current_user.company == Order.find(params[:id]).company }
  def show
    # Accessible to company managers unless suspended, and to clients if the client's company matches the order's company
  end

  # Dynamic-only rules (no roles required, can be used with custom policies)
  grant_access action: :index, if: -> { OrdersPolicy.new(current_user).index? }
  def index
    # Accessible to company managers unless suspended, and to users based on custom policy logic
  end

  private

  def company_manager?
    current_user.manager_of?(Company.find(params[:company_id]))
  end

  def suspended?
    current_user.suspended?
  end
end
```

You can pass a dynamic rule as an `if` or `unless` argument, which can be a symbol (method name) or a proc. Symbols refer to instance methods, and procs are evaluated in the controller at request time.

Dynamic rules can be combined with role-based rules. But they can also be used alone, which allows you to use Rabarber as a policy-based authorization library by calling your own custom policy when needed.

## When Unauthorized

By default, when unauthorized, Rabarber will redirect back (HTML format) or return 403 (other formats). You can override `when_unauthorized` method to customize unauthorized access behavior:

```rb
class ApplicationController < ActionController::Base
  include Rabarber::Authorization

  with_authorization

  private

  def when_unauthorized
    head :not_found # Custom behavior to hide existence of protected resources
  end
end
```

The `when_unauthorized` method can be overridden in any controller to provide controller-specific unauthorized access handling.

## Context / Multi-tenancy

Rabarber supports multi-tenancy through its context feature. All Rabarber methods accept a `context` parameter, allowing you to work with roles within specific scopes. By default, context is `nil`, meaning roles are global. Context can also be an instance of an `ActiveRecord` model or a class.

For example, in a project management app, you might want users to have different roles in different projects - someone could be an `owner` in one project but just a `member` in another.

### Contextual Role Assignment And Queries

```rb
# Assign roles within a specific model instance
user.assign_roles(:owner, context: project)
user.assign_roles(:member, context: project)

# Assign roles within a model class
user.assign_roles(:admin, context: Project)

# Check contextual roles
user.has_role?(:owner, context: project)
user.has_role?(:admin, context: Project)

# Revoke roles
user.revoke_roles(:owner, context: project)

# Get user roles
user.roles(context: project)

# Get users with a role
User.with_role(:member, context: project)
```

### Contextual Role Management

```rb
# Create a new role within a context
Rabarber.create_role(:admin, context: Project)

# Rename a role within a context
Rabarber.rename_role(:admin, :owner, context: project)

# Remove a contextual role
Rabarber.delete_role(:admin, context: project)

# List available roles within a specific context
Rabarber.roles(context: project)
```

### Contextual Authorization

In authorization rules, in addition to specifying context explicitly, you can also provide a proc or a symbol (similar to dynamic rules):

```rb
class ProjectsController < ApplicationController
  grant_access roles: :admin, context: Project

  # Method-based context resolution
  grant_access action: :show, roles: :member, context: :current_project
  def show
    # Accessible to Project admin and members of the current project
  end

  # Proc-based context resolution
  grant_access action: :update, roles: :owner, context: -> { Project.find(params[:id]) }
  def update
    # Accessible to Project admin and owner of the current project
  end

  private

  def current_project
    @current_project ||= Project.find(params[:id])
  end
end
```

### Orphaned Context

When a context object is deleted from your database, its associated roles become orphaned and ignored by Rabarber.

To clean up orphaned context roles, use:

```rb
Rabarber.prune
```

### Context Migrations

When you rename or remove models used as contexts, you need to update Rabarber's stored context data accordingly. Use these irreversible data migrations:

```rb
# Rename a context class (e.g., when you rename your Ticket model to Task)
migrate_authorization_context!("Ticket", "Task")

# Remove orphaned context data (e.g., when you delete the Ticket model entirely)
delete_authorization_context!("Ticket")
```

## View Helpers

Include view helpers in your application:

```rb
module ApplicationHelper
  include Rabarber::Helpers
end
```

Use conditional rendering based on roles:

```erb
<%= visible_to(:admin, :manager) do %>
  <div class="admin-panel">
    <!-- Admin/Manager content -->
  </div>
<% end %>

<%= hidden_from(:guest) do %>
  <div class="member-content">
    <!-- Content hidden from guests -->
  </div>
<% end %>

<%= visible_to(:owner, context: @project) do %>
  <div class="project-owner-panel">
    <!-- Content visible to project owners -->
  </div>
<% end %>
```

## Getting Help and Contributing

### Getting Help
Have a question or need assistance? Open a discussion in our [discussions section](https://github.com/enjaku4/rabarber/discussions) for:
- Usage questions
- Implementation guidance
- Feature suggestions

### Reporting Issues
Found a bug? Please [create an issue](https://github.com/enjaku4/rabarber/issues) with:
- A clear description of the problem
- Steps to reproduce the issue
- Your environment details (Rails version, Ruby version, etc.)

### Contributing Code
Ready to contribute? You can:
- Fix bugs by submitting pull requests
- Improve documentation
- Add new features (please discuss first in our [discussions section](https://github.com/enjaku4/rabarber/discussions))

Before contributing, please read the [contributing guidelines](https://github.com/enjaku4/rabarber/blob/main/CONTRIBUTING.md)

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/enjaku4/rabarber/blob/main/LICENSE.txt).

## Code of Conduct

Everyone interacting in the Rabarber project is expected to follow the [code of conduct](https://github.com/enjaku4/rabarber/blob/main/CODE_OF_CONDUCT.md).

## Old Versions

Only the latest major version is supported. Older versions are obsolete and not maintained, but their READMEs are available here for reference:

[v4.x.x](https://github.com/enjaku4/rabarber/blob/9353e70281971154d5acd70693620197a132c543/README.md) | [v3.x.x](https://github.com/enjaku4/rabarber/blob/3bb273de7e342004abc7ef07fa4d0a9a3ce3e249/README.md)
 | [v2.x.x](https://github.com/enjaku4/rabarber/blob/875b357ea949404ddc3645ad66eddea7ed4e2ee4/README.md) | [v1.x.x](https://github.com/enjaku4/rabarber/blob/b81428429404e197d70317b763e7b2a21e02c296/README.md)
