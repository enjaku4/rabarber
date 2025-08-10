# Rabarber: Role-Based Authorization for Rails

[![Gem Version](https://badge.fury.io/rb/rabarber.svg)](http://badge.fury.io/rb/rabarber)
[![Github Actions badge](https://github.com/brownboxdev/rabarber/actions/workflows/ci.yml/badge.svg)](https://github.com/brownboxdev/rabarber/actions/workflows/ci.yml)

Rabarber is a role-based authorization library for Ruby on Rails that focuses on controller-level access control. Rather than answering domain questions like "can this user create a post?", Rabarber answers "can this user access the create post endpoint?", providing a clean separation between authorization and business logic.

**Key Features:**

- Role-based authorization
- Controller-level access control
- Multi-tenancy support through contextual roles
- Dynamic authorization with conditional logic
- View helpers for role-based content rendering

## Table of Contents

**Gem Usage:**
  - [Installation](#installation)
  - [Configuration](#configuration)
  - [User Role Methods](#user-role-methods)
  - [Role Management](#role-management)
  - [Controller Authorization](#controller-authorization)
  - [Dynamic Rules](#dynamic-rules)
  - [Multi-tenancy / Context](#multi-tenancy--context)
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

Generate the migration for role storage (replace `users` with your user table name if different):

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

Configure Rabarber in an initializer if customization is needed:

```rb
Rabarber.configure do |config|
  config.cache_enabled = true                 # Enable role caching (default: true)
  config.current_user_method = :current_user  # Method to access current user (default: :current_user)
  config.user_model_name = "User"             # User model name (default: "User")
end
```

To clear the role cache manually:

```rb
Rabarber::Cache.clear
```

## User Role Methods

Your user model is automatically augmented with role management methods:

### Role Assignment

```rb
# Assign roles (creates roles if they don't exist)
user.assign_roles(:accountant, :manager)

# Assign only existing roles
user.assign_roles(:accountant, :manager, create_new: false)

# Revoke specific roles
user.revoke_roles(:accountant, :manager)

# Revoke all roles
user.revoke_all_roles
```

### Role Queries

```rb
# Check if user has any of the specified roles
user.has_role?(:accountant, :manager)

# Get user's roles
user.roles

# Get all roles grouped by context
user.all_roles
```

## Role Management

### Direct Role Operations

```rb
# Create a new role
Rabarber::Role.add(:admin)

# Rename a role
Rabarber::Role.rename(:admin, :administrator)
Rabarber::Role.rename(:admin, :administrator, force: true) # Force if role is assigned to users

# Remove a role
Rabarber::Role.remove(:admin)
Rabarber::Role.remove(:admin, force: true) # Force if role is assigned to users

# List available roles
Rabarber::Role.names
Rabarber::Role.all_names # All roles grouped by context

# Get users assigned to a role
Rabarber::Role.assignees(:admin)
```
<!-- TODO: all Rabarber::Role methods should be namespaced under Rabarber to hide existence of the model -->
<!-- TODO: i.e. names and all_names will become Rabarber.roles(context:) and Rabarber.all_roles, etc. -->
<!-- TODO: assignees should probably go to roleable model, e.g. User.with_role(role, context:) -->

## Controller Authorization

### Basic Setup

Include the authorization module and configure protection:

```rb
class ApplicationController < ActionController::Base
  include Rabarber::Authorization

  with_authorization # Enable authorization for all actions
end

class InvoicesController < ApplicationController
  with_authorization only: [:update, :destroy] # Selective authorization
end
```

Authorization requires an authenticated user.

### Skip Authorization

You can also selectively skip authorization:

```rb
class TicketsController < ApplicationController
  skip_authorization except: [:create, :update, :destroy]
end
```

### Authorization Rules

Define access rules using `grant_access`:

```rb
class TicketsController < ApplicationController
  # Controller-wide access
  grant_access roles: :admin

  # Action-specific access
  grant_access action: :index, roles: [:manager, :support]
  def index
    # Accessible to admin, manager, and support roles
  end
end
```

### Additive Rules

Rules are additive across inheritance chains and for the same actions:

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

Omit roles to allow unrestricted access:

```rb
class UnrestrictedController < ApplicationController
  grant_access # Allow all users
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

### Custom Unauthorized Handling

Override `when_unauthorized` method to customize unauthorized access behavior:

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

By default, Rabarber will redirect back (HTML format) or return 403 (other formats).

## Dynamic Rules

Add conditional logic to authorization rules:

```rb
class OrdersController < ApplicationController
  # Method-based conditions
  grant_access roles: :manager, if: :company_manager?, unless: :suspended?

  # Proc-based conditions
  grant_access action: :show, roles: :client, if: -> { current_user.company_id == Order.find(params[:id]).company_id }
  def show
    # Accessible to company managers unless suspended, and to clients if the client's company matches the order's company
  end

  # Dynamic-only rules (no roles required, can be used with custom policies)
  grant_access action: :index, if: -> { OrdersPolicy.new(current_user).can_access?(:index) }
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

## Multi-tenancy / Context

All Rabarber methods accept a `context` parameter, allowing you to work with roles within specific scopes. By default, context is `nil`, meaning roles are global.

### Contextual Role Assignment

```rb
# Assign roles within a specific model instance
user.assign_roles(:owner, context: project)
user.assign_roles(:member, context: project)

# Assign roles within a model class (e.g., project admin)
user.assign_roles(:admin, context: Project)

# Check contextual roles
user.has_role?(:owner, context: project)
user.has_role?(:admin, context: Project)

# Revoke roles within a specific context
user.revoke_roles(:owner, context: project)

# Get roles within context
user.roles(context: project)
```

### Contextual Role Management

```rb
# Create a new role within a specific context
Rabarber::Role.add(:admin, context: Project)

# Rename a role within a specific context
Rabarber::Role.rename(:admin, :owner, context: Project)

# Remove a role within a specific context
Rabarber::Role.remove(:admin, context: project)

# Get roles within context
Rabarber::Role.names(context: Project)
```

### Contextual Authorization

```rb
class ProjectsController < ApplicationController
  # Class-based context
  grant_access roles: :admin, context: Project

  # Instance-based context (method)
  grant_access action: :show, roles: :member, context: :current_project
  def show
    # Accessible to Project admin and members of the current project
  end

  # Instance-based context (proc)
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

### Context Migrations

Handle context changes when models are renamed or removed. These are irreversible data migrations.

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

Before contributing, please read the [contributing guidelines](https://github.com/brownboxdev/rabarber/blob/main/CONTRIBUTING.md)

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/brownboxdev/rabarber/blob/main/LICENSE.txt).

## Code of Conduct

Everyone interacting in the Rabarber project is expected to follow the [code of conduct](https://github.com/brownboxdev/rabarber/blob/main/CODE_OF_CONDUCT.md).

## Old Versions

Only the latest major version is supported. Older versions are obsolete and not maintained, but their READMEs are available here for reference:

[v4.x.x](https://github.com/brownboxdev/rabarber/blob/9353e70281971154d5acd70693620197a132c543/README.md) | [v3.x.x](https://github.com/brownboxdev/rabarber/blob/3bb273de7e342004abc7ef07fa4d0a9a3ce3e249/README.md)
 | [v2.x.x](https://github.com/brownboxdev/rabarber/blob/875b357ea949404ddc3645ad66eddea7ed4e2ee4/README.md) | [v1.x.x](https://github.com/brownboxdev/rabarber/blob/b81428429404e197d70317b763e7b2a21e02c296/README.md)
