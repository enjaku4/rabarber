# Rabarber

Simple role-based authorization library for Ruby on Rails with multi-tenancy support.

[![Gem Version](https://badge.fury.io/rb/rabarber.svg)](https://badge.fury.io/rb/rabarber)
[![Ruby](https://github.com/brownboxdev/rabarber/actions/workflows/ruby.yml/badge.svg)](https://github.com/brownboxdev/rabarber/actions/workflows/ruby.yml)

## Quick Start

```ruby
class TicketsController < ApplicationController
  grant_access roles: :admin
  grant_access action: :index, roles: :manager

  def index
    # Only accessible by admin and manager
  end

  def delete
    # Only accessible by admin
  end
end
```

## Installation

Add to your Gemfile:

```ruby
gem "rabarber"
```

Install and generate migration:

```bash
bundle install
rails g rabarber:roles users        # or your user table name
rails g rabarber:roles users --uuid # for UUID primary keys
rails db:migrate
```

## Configuration

```ruby
# config/initializers/rabarber.rb
Rabarber.configure do |config|
  config.cache_enabled = true                # Cache roles (default: true)
  config.current_user_method = :current_user # Current user method (default: :current_user)
  config.user_model_name = "User"            # User model name (default: "User")
end
```

## Role Management

### User Role Methods

```ruby
# Assign roles
user.assign_roles(:accountant, :marketer)
user.assign_roles(:admin, create_new: false) # Don't auto-create roles

# Revoke roles
user.revoke_roles(:accountant, :marketer)

# Check roles
user.has_role?(:admin)           # true if user has admin role
user.has_role?(:admin, :manager) # true if user has any of these roles

# List roles
user.roles     # User's roles
user.all_roles # All roles grouped by context
```

### Role Class Methods

```ruby
# Add/remove roles
Rabarber::Role.add(:admin)                    # Returns true/false
Rabarber::Role.remove(:admin)                 # Must not be assigned to users
Rabarber::Role.remove(:admin, force: true)    # Force removal

# Rename roles
Rabarber::Role.rename(:admin, :administrator)
Rabarber::Role.rename(:admin, :administrator, force: true)

# List roles
Rabarber::Role.names     # All role names
Rabarber::Role.all_names # All roles grouped by context

# Get assignees
Rabarber::Role.assignees(:admin) # Users with admin role
```

## Authorization

### Controller Setup

```ruby
class ApplicationController < ActionController::Base
  include Rabarber::Authorization
  with_authorization # Enable for all actions
end

class InvoicesController < ApplicationController
  with_authorization only: [:update, :destroy] # Enable selectively
end
```

### Access Rules

```ruby
class InvoicesController < ApplicationController
  # Action-specific rules
  grant_access action: :index, roles: [:accountant, :admin]
  grant_access action: :destroy, roles: :admin

  # Controller-wide rules
  grant_access roles: [:admin, :manager]

  # Unrestricted access
  grant_access # Allow everyone
  grant_access action: :index # Allow everyone to index
end
```

### Rule Inheritance

Rules from parent controllers are inherited and combined:

```ruby
class BaseController < ApplicationController
  grant_access roles: :admin # Admins can access everything
end

class InvoicesController < BaseController
  grant_access roles: :accountant # Accountants can also access invoices
  # Both admin and accountant can now access InvoicesController
end
```

### Dynamic Rules

```ruby
class OrdersController < ApplicationController
  grant_access roles: :manager, if: :company_manager?, unless: :fired?
  grant_access action: :show, roles: :accountant, unless: -> { order_total_too_high? }

  private

  def company_manager?
    Company.find(params[:company_id]).manager == current_user
  end

  def fired?
    current_user.fired?
  end
end

# Policy-based authorization
class InvoicesController < ApplicationController
  grant_access action: :index, if: -> { InvoicesPolicy.new(current_user).can_access?(:index) }
end
```

## Multi-tenancy (Context)

Roles can be scoped to specific contexts for multi-tenant applications:

```ruby
# Assign context-specific roles
user.assign_roles(:owner, context: project)
user.assign_roles(:admin, context: Project) # Class-level context

# Check context-specific roles
user.has_role?(:owner, context: project)
user.has_role?(:admin, context: Project)

# List context-specific roles
user.roles(context: project)
Rabarber::Role.names(context: Project)
```

### Context in Controllers

```ruby
class ProjectsController < ApplicationController
  grant_access roles: :admin, context: Project
  grant_access action: :show, roles: :member, context: :project
  grant_access action: :update, roles: :owner, context: -> { Project.find(params[:id]) }

  private

  def project
    Project.find(params[:id])
  end
end
```

### Context Migration Helpers

For renamed or deleted context classes:

```ruby
# In a migration
migrate_authorization_context!(old_context, new_context) # Rename context
delete_authorization_context!(context)                   # Remove context roles
```

## Customization

### Unauthorized Handling

Override the default unauthorized behavior:

```ruby
class ApplicationController < ActionController::Base
  include Rabarber::Authorization
  with_authorization

  private

  def when_unauthorized
    head :not_found # Return 404 instead of redirect/401
  end
end
```

### Skip Authorization

```ruby
class TicketsController < ApplicationController
  skip_authorization only: :index
  skip_authorization except: [:create, :update, :destroy]
end
```

## View Helpers

```ruby
# In ApplicationHelper
module ApplicationHelper
  include Rabarber::Helpers
end
```

```erb
<%= visible_to(:admin, :manager) do %>
  <p>Only admins and managers see this</p>
<% end %>

<%= hidden_from(:accountant) do %>
  <p>Everyone except accountants see this</p>
<% end %>

<!-- With context -->
<%= visible_to(:owner, context: @project) do %>
  <p>Only project owners see this</p>
<% end %>
```

## Cache Management

Clear role cache when needed:

```ruby
Rabarber::Cache.clear
```

## Requirements

- Ruby 2.7+
- Rails 6.1+

## Contributing

1. Fork the repository
2. Create your feature branch
3. Make your changes with tests
4. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## Versioning

Only the latest major version is supported. Previous versions:
[v4.x.x](https://github.com/brownboxdev/rabarber/blob/9353e70281971154d5acd70693620197a132c543/README.md) |
[v3.x.x](https://github.com/brownboxdev/rabarber/blob/3bb273de7e342004abc7ef07fa4d0a9a3ce3e249/README.md) |
[v2.x.x](https://github.com/brownboxdev/rabarber/blob/875b357ea949404ddc3645ad66eddea7ed4e2ee4/README.md) |
[v1.x.x](https://github.com/brownboxdev/rabarber/blob/b81428429404e197d70317b763e7b2a21e02c296/README.md)

## License

[MIT License](LICENSE.txt)
