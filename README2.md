# Rabarber

Simple role-based authorization library for Ruby on Rails with multi-tenancy support.

Rabarber helps you manage user permissions in your Rails application without the complexity of policy-based systems. Think of it as a straightforward way to say "only admins can delete posts" or "accountants can see invoices but not marketing data" - all with clean, readable code that makes authorization logic crystal clear.

[![Gem Version](https://badge.fury.io/rb/rabarber.svg)](https://badge.fury.io/rb/rabarber)
[![Ruby](https://github.com/brownboxdev/rabarber/actions/workflows/ruby.yml/badge.svg)](https://github.com/brownboxdev/rabarber/actions/workflows/ruby.yml)

## Quick Start

Here's how simple it is to secure your controllers:

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

That's it! Admins get full access, managers can only view the index.

## Installation

Add to your Gemfile:

```ruby
gem "rabarber"
```

Install and generate the necessary database migration:

```bash
bundle install
rails g rabarber:roles users        # Replace 'users' with your user table name
rails g rabarber:roles users --uuid # Add --uuid if you're using UUID primary keys
rails db:migrate
```

## Configuration

Rabarber works out of the box, but you can customize it if needed:

```ruby
# config/initializers/rabarber.rb
Rabarber.configure do |config|
  config.cache_enabled = true                # Cache roles for better performance (default: true)
  config.current_user_method = :current_user # How to get the current user (default: :current_user)
  config.user_model_name = "User"            # Your user model name (default: "User")
end
```

## Role Management

Rabarber automatically adds role methods to your user model. Here's how to use them:

### Working with User Roles

```ruby
# Assign roles to users
user.assign_roles(:accountant, :marketer)
user.assign_roles(:admin, create_new: false) # Won't create new roles if they don't exist

# Remove roles from users
user.revoke_roles(:accountant, :marketer)

# Check what roles a user has
user.has_role?(:admin)           # true if user has admin role
user.has_role?(:admin, :manager) # true if user has ANY of these roles

# Get a user's roles
user.roles     # Array of this user's roles
user.all_roles # All roles grouped by context (useful for multi-tenancy)
```

### Managing Roles System-Wide

Sometimes you need to manage the roles themselves:

```ruby
# Create new roles
Rabarber::Role.add(:admin)                    # Returns true if created, false if exists

# Remove roles (but only if no users have them)
Rabarber::Role.remove(:admin)                 # Fails if users have this role
Rabarber::Role.remove(:admin, force: true)    # Removes even if users have it

# Rename roles across your entire system
Rabarber::Role.rename(:admin, :administrator)
Rabarber::Role.rename(:admin, :administrator, force: true) # Even if users are assigned

# See what roles exist
Rabarber::Role.names     # All available role names
Rabarber::Role.all_names # All roles grouped by context

# Find who has a specific role
Rabarber::Role.assignees(:admin) # Returns all users with admin role
```

## Authorization

This is where Rabarber shines - clean, readable authorization rules.

### Setting Up Your Controllers

First, enable authorization in your base controller:

```ruby
class ApplicationController < ActionController::Base
  include Rabarber::Authorization
  with_authorization # Enables authorization for all actions
end

# Or enable it selectively
class InvoicesController < ApplicationController
  with_authorization only: [:update, :destroy] # Only these actions require authorization
end
```

**Important:** Make sure users are authenticated before authorization runs. Rabarber checks permissions, not identity.

### Defining Access Rules

```ruby
class InvoicesController < ApplicationController
  # Specific actions for specific roles
  grant_access action: :index, roles: [:accountant, :admin]
  grant_access action: :destroy, roles: :admin

  # Grant access to entire controller
  grant_access roles: [:admin, :manager] # These roles can access any action

  # Allow public access
  grant_access # Everyone can access this controller
  grant_access action: :index # Everyone can access just the index action
end
```

### How Rule Inheritance Works

Rules cascade down from parent controllers and combine (they don't override):

```ruby
class BaseController < ApplicationController
  grant_access roles: :admin # Admins can access everything
end

class InvoicesController < BaseController
  grant_access roles: :accountant # Accountants can also access invoices
  # Result: Both admins AND accountants can access InvoicesController
end
```

This is powerful for creating hierarchical permissions!

### Dynamic Authorization Rules

For complex scenarios where roles aren't enough:

```ruby
class OrdersController < ApplicationController
  # Combine roles with custom logic
  grant_access roles: :manager, if: :company_manager?, unless: :fired?
  grant_access action: :show, roles: :accountant, unless: -> { order_too_expensive? }

  private

  def company_manager?
    Company.find(params[:company_id]).manager == current_user
  end

  def fired?
    current_user.fired?
  end
end

# Use it like a policy system
class InvoicesController < ApplicationController
  grant_access action: :index, if: -> { InvoicesPolicy.new(current_user).can_access?(:index) }
end
```

You can use symbols (for instance methods) or procs for maximum flexibility.

## Multi-tenancy (Context)

This is one of Rabarber's most powerful features. Instead of global roles, you can scope them to specific objects or classes:

```ruby
# Make someone an owner of a specific project
user.assign_roles(:owner, context: project)

# Make someone an admin of ALL projects
user.assign_roles(:admin, context: Project)

# Check context-specific roles
user.has_role?(:owner, context: project)      # Owner of this project?
user.has_role?(:admin, context: Project)      # Admin of all projects?

# See roles within a context
user.roles(context: project)           # This user's roles for this project
Rabarber::Role.names(context: Project) # All available project-level roles
```

### Context in Authorization Rules

```ruby
class ProjectsController < ApplicationController
  # Global project admins can do anything
  grant_access roles: :admin, context: Project

  # Project members can view their projects
  grant_access action: :show, roles: :member, context: :project

  # Project owners can update their projects
  grant_access action: :update, roles: :owner, context: -> { Project.find(params[:id]) }

  private

  def project
    Project.find(params[:id])
  end
end
```

This enables powerful multi-tenant applications where users have different roles in different contexts.

### Handling Context Changes

When you rename or delete model classes used as contexts:

```ruby
# In a migration - these operations are irreversible!
migrate_authorization_context!(old_context, new_context) # Rename context
delete_authorization_context!(context)                   # Remove all roles for deleted context
```

## Customization

### Handling Unauthorized Access

By default, Rabarber redirects HTML requests and returns 401 for API requests. Customize this:

```ruby
class ApplicationController < ActionController::Base
  include Rabarber::Authorization
  with_authorization

  private

  def when_unauthorized
    head :not_found # Pretend the resource doesn't exist
    # or redirect_to login_path, alert: "Please log in"
    # or render json: { error: "Forbidden" }, status: :forbidden
  end
end
```

Different controllers can handle unauthorized access differently.

### Skipping Authorization

Sometimes you need exceptions:

```ruby
class TicketsController < ApplicationController
  skip_authorization only: :index              # Public index page
  skip_authorization except: [:create, :update, :destroy] # Only CUD operations need auth
end
```

## View Helpers

Make your views role-aware:

```ruby
# In ApplicationHelper
module ApplicationHelper
  include Rabarber::Helpers
end
```

```erb
<%= visible_to(:admin, :manager) do %>
  <div class="admin-panel">
    <p>Only admins and managers see this section</p>
  </div>
<% end %>

<%= hidden_from(:accountant) do %>
  <p>Everyone except accountants can see this</p>
<% end %>

<!-- Works with context too -->
<%= visible_to(:owner, context: @project) do %>
  <%= link_to "Edit Project", edit_project_path(@project) %>
<% end %>
```

These helpers respect the same role and context logic as your controllers.

## Performance

### Cache Management

Roles are cached by default for better performance. Clear the cache when needed:

```ruby
Rabarber::Cache.clear # Usually not needed, but available if required
```

## Requirements

- Ruby 2.7+
- Rails 6.1+

## Contributing

We welcome contributions! Whether it's a bug report, feature request, or code contribution:

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Make your changes with tests
4. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## Versioning

We only support the latest major version. Previous versions are available for reference:

[v4.x.x](https://github.com/brownboxdev/rabarber/blob/9353e70281971154d5acd70693620197a132c543/README.md) |
[v3.x.x](https://github.com/brownboxdev/rabarber/blob/3bb273de7e342004abc7ef07fa4d0a9a3ce3e249/README.md) |
[v2.x.x](https://github.com/brownboxdev/rabarber/blob/875b357ea949404ddc3645ad66eddea7ed4e2ee4/README.md) |
[v1.x.x](https://github.com/brownboxdev/rabarber/blob/b81428429404e197d70317b763e7b2a21e02c296/README.md)

## License

[MIT License](LICENSE.txt)
