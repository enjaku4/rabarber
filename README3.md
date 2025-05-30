# Rabarber: Role-Based Authorization for Rails

[![Gem Version](https://badge.fury.io/rb/rabarber.svg)](http://badge.fury.io/rb/rabarber)
[![Github Actions badge](https://github.com/brownboxdev/rabarber/actions/workflows/ci.yml/badge.svg)](https://github.com/brownboxdev/rabarber/actions/workflows/ci.yml)

Rabarber is a role-based authorization library for Ruby on Rails that provides comprehensive tools for managing user roles and defining authorization rules. With built-in support for multi-tenancy and fine-grained access control, Rabarber gives you complete control over your authorization logic without imposing business decisions.

**Key Features:**

- Role-based authorization with flexible rule definitions
- Multi-tenancy support through contextual roles
- Dynamic authorization rules with conditional logic
- Controller and view integration
- Database-backed role management
- No pre-defined business logic — just the essential authorization building blocks

**Quick Example:**

Consider a CRM system where users with different roles have distinct access levels. The `accountant` role can interact with invoices but cannot access marketing information, while the `marketer` role has access to marketing-related data:

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

This means `admin` users can access everything in `TicketsController`, while `manager` role can access only the `index` action.

## Table of Contents

**Gem Usage:**
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
  - [Contributing](#contributing)
  - [License](#license)
  - [Code of Conduct](#code-of-conduct)
  - [Old Versions](#old-versions)

## Installation

Add Rabarber to your Gemfile:

```rb
gem "rabarber"
```

Install the gem:

```bash
bundle install
```

Generate a migration to create tables for storing roles (replace `users` with your user table name if different):

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

If customization is required, configure Rabarber in an initializer:

```rb
# These are the default values; you can change them as needed
Rabarber.configure do |config|
  config.cache_enabled = true                # Enable role caching to avoid unnecessary database queries
  config.current_user_method = :current_user # Method used to access the currently authenticated user
  config.user_model_name = "User"            # Your user model name
end
```

Note: If you need to clear the role cache, use `Rabarber::Cache.clear`.

## Role Assignments

Your user model is automatically extended with role management methods:

### Assigning Roles

```rb
# Assign roles (creates roles if they don't exist)
user.assign_roles(:accountant, :marketer)

# Assign only existing roles (prevents automatic creation)
user.assign_roles(:accountant, :marketer, create_new: false)
```

### Revoking Roles

```rb
# Revoke specific roles
user.revoke_roles(:accountant, :marketer)

# Revoke all roles
user.revoke_all_roles
```

### Checking Roles

```rb
# Check if user has any of the specified roles
user.has_role?(:accountant, :marketer) # Returns true if user has at least one role

# Get user's roles
user.roles

# Get all roles grouped by context
user.all_roles
```

### Finding Role Assignees

```rb
# Get all users assigned to a specific role
Rabarber::Role.assignees(:admin)
```

## Role Management

Manage roles directly using these methods:

### Creating and Modifying Roles

```rb
# Add a new role
Rabarber::Role.add(:admin)

# Rename a role
Rabarber::Role.rename(:admin, :administrator)

# Force rename even if role is assigned to users
Rabarber::Role.rename(:admin, :administrator, force: true)

# Remove a role
Rabarber::Role.remove(:admin)

# Force removal even if role is assigned to users
Rabarber::Role.remove(:admin, force: true)
```

### Listing Roles

```rb
# List available roles
Rabarber::Role.names

# List all roles grouped by context
Rabarber::Role.all_names
```

## Authorization Rules

### Basic Setup

Include the authorization module and configure protection:

```rb
class ApplicationController < ActionController::Base
  include Rabarber::Authorization

  with_authorization # Require authorization by default
end

class InvoicesController < ApplicationController
  with_authorization only: [:update, :destroy] # Selective authorization
end
```

You must ensure the user is authenticated before authorization checks are performed.

### Defining Access Rules

```rb
class InvoicesController < ApplicationController
  # Grant access to specific actions
  grant_access action: :index, roles: [:accountant, :admin]
  def index
    @invoices = Invoice.all
    @invoices = @invoices.paid if current_user.has_role?(:accountant)
  end

  grant_access action: :destroy, roles: :admin
  def destroy
    # ...
  end
end
```

### Controller-Wide Rules

```rb
class BaseController < ApplicationController
  grant_access roles: [:admin, :manager]
end

class InvoicesController < BaseController
  grant_access roles: :accountant # Adds to inherited rules

  def index
    # Accessible to admin, manager, and accountant
  end
end
```

### Unrestricted Access

```rb
class OrdersController < ApplicationController
  grant_access # Allow everyone
end

class InvoicesController < ApplicationController
  grant_access action: :index # Allow everyone to access index
  def index
    # ...
  end
end
```

## Dynamic Authorization Rules

For complex scenarios, use dynamic authorization with conditional logic:

```rb
class OrdersController < ApplicationController
  grant_access roles: :manager, if: :company_manager?, unless: :fired?

  # Using procs for inline conditions
  grant_access action: :index, roles: [:secretary, :accountant],
               if: -> { InvoicesPolicy.new(current_user).can_access?(:index) }
  def index
    # ...
  end

  grant_access action: :show, roles: :accountant,
               unless: -> { Invoice.find(params[:id]).total > 10_000 }
  def show
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
```

### Policy-Based Authorization

Use Rabarber with your own policy classes:

```rb
class InvoicesController < ApplicationController
  grant_access action: :index, if: -> { InvoicesPolicy.new(current_user).can_access?(:index) }

  def index
    # ...
  end
end
```

## Context / Multi-tenancy

Rabarber supports multi-tenancy through contextual roles, allowing you to scope roles to specific models or classes:

### Contextual Role Assignment

```rb
# Assign roles within a specific project context
user.assign_roles(:owner, context: project)
another_user.assign_roles(:member, context: project)

# Assign roles for all projects (class-level context)
user.assign_roles(:admin, context: Project)
```

### Checking Contextual Roles

```rb
# Check roles within context
user.has_role?(:owner, context: project)
user.has_role?(:admin, context: Project)

# Get roles for specific context
user.roles(context: project)
Rabarber::Role.names(context: Project)
```

### Authorization with Context

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

### Context Migration Helpers

For handling renamed or deleted context classes, use these migration helpers:

```rb
# Rename a context (irreversible)
migrate_authorization_context!(old_context, new_context)

# Remove roles tied to deleted context (irreversible)
delete_authorization_context!(context)
```

## When Unauthorized

Customize unauthorized access handling by overriding the `when_unauthorized` method:

```rb
class ApplicationController < ActionController::Base
  include Rabarber::Authorization

  with_authorization

  private

  # By default redirects back with fallback to root path for HTML requests,
  # returns 401 Unauthorized for other formats
  def when_unauthorized
    head :not_found # Pretend the page doesn't exist
  end
end
```

## Skip Authorization

Skip authorization checks when needed:

```rb
class TicketsController < ApplicationController
  skip_authorization only: :index
  skip_authorization except: [:create, :update, :destroy]
end
```

## View Helpers

Enable view helpers by including the module in your helper:

```rb
module ApplicationHelper
  include Rabarber::Helpers
end
```

Use helpers in your views:

```erb
<%= visible_to(:admin, :manager) do %>
  <p>Visible only to admins and managers</p>
<% end %>

<%= hidden_from(:accountant) do %>
  <p>Accountant cannot see this</p>
<% end %>

<!-- With context -->
<%= visible_to(:owner, context: @project) do %>
  <p>Only project owners can see this</p>
<% end %>
```

## Contributing

### Getting Help
Have a question or need assistance? Open a discussion in our [discussions section](https://github.com/brownboxdev/rabarber/discussions) for:
- Usage questions
- Implementation guidance
- Feature suggestions

### Reporting Issues
Found a bug? Please [create an issue](https://github.com/brownboxdev/rabarber/issues) with:
- A clear description of the problem
- Steps to reproduce the issue
- Your environment details (Rails version, Ruby version, etc.)

### Contributing Code
Ready to contribute? You can:
- Fix bugs by submitting pull requests
- Improve documentation
- Add new features (please discuss first in our [discussions section](https://github.com/brownboxdev/rabarber/discussions))

Before contributing, please read the [contributing guidelines](https://github.com/brownboxdev/rabarber/blob/main/CONTRIBUTING.md).

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/brownboxdev/rabarber/blob/main/LICENSE.txt).

## Code of Conduct

Everyone interacting in the Rabarber project is expected to follow the [code of conduct](https://github.com/brownboxdev/rabarber/blob/main/CODE_OF_CONDUCT.md).

## Old Versions

Only the latest major version is supported. Older versions are obsolete and not maintained, but their READMEs are available here for reference:

[v4.x.x](https://github.com/brownboxdev/rabarber/blob/9353e70281971154d5acd70693620197a132c543/README.md) | [v3.x.x](https://github.com/brownboxdev/rabarber/blob/3bb273de7e342004abc7ef07fa4d0a9a3ce3e249/README.md) | [v2.x.x](https://github.com/brownboxdev/rabarber/blob/875b357ea949404ddc3645ad66eddea7ed4e2ee4/README.md) | [v1.x.x](https://github.com/brownboxdev/rabarber/blob/b81428429404e197d70317b763e7b2a21e02c296/README.md)
