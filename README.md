# Rabarber: Simplified Authorization for Rails

Rabarber is an authorization library primarily designed for use in the web layer of your application, specifically in controllers and views.

Rabarber takes a slightly different approach compared to some popular libraries. Instead of answering, "Who can perform actions on this record?" it focuses on a question: "Who can access this endpoint?" In Rabarber, authorization is expressed not as "A user with role 'editor' can edit a post," but rather as "A user with the role 'editor' can access a post editing endpoint."

#### Example Usage:

Consider a CRM application where users in different roles have distinct access levels. For instance, an accountant role can interact with invoices and orders but cannot access marketing information, while the marketer role has access to marketing-related data.

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

Finally, run the migration to apply the changes to the database:

```
rails db:migrate
```

## Configuration

Seamlessly include Rabarber in your application by adding the following initializer:

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
- `must_have_roles` must be a boolean, determining whether a user with no roles can access endpoints permitted to everyone. The default value is `false` (allowing users without roles to access endpoints permitted for everyone).
- `when_unauthorized` must be a lambda where you can define your actions when access is not authorized (`controller` is the instance of the controller where the code is executed). By default, the user is redirected back for HTML requests; otherwise, a 401 Unauthorized response is sent.

## Usage

Include the `Rabarber::HasRoles` module in your model representing application users:

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
By default, the `#assign_roles` method will automatically create any roles that don't exist. If you want to assign only existing roles and prevent the creation of new ones, use the method with the `create_new: false` argument:
```rb
user.assign_roles(:accountant, :marketer, create_new: false)
```

#### `#revoke_roles`

To revoke roles from the user, use:

```rb
user.revoke_roles(:accountant, :marketer)
```
If any of the specified roles doesn't exist or the user doesn't have such a role, it will be ignored.

#### `#has_role?`

To check whether the user has a role, use:

```rb
user.has_role?(:accountant, :marketer)
```

It returns `true` if the user has at least one role and `false` otherwise.

#### `#roles`

View all roles assigned to the user:

```rb
user.roles
```

Utilize these methods to manipulate user roles. For example, create a custom UI for managing roles or assign necessary roles during migration or runtime (e.g., when the user is created). Adapt them to fit the requirements of your app.

If you need to list all the role names, use:

```rb
Rabarber::Role.names
```

---

### Authorization Rules

Include the `Rabarber::Authorization` module in the controller to which (specifically to it and its children) you want authorization rules to be applied. Typically, it is `ApplicationController`, but it can be any controller.

```rb
class ApplicationController < ActionController::Base
  include Rabarber::Authorization
  ...
end
```
This adds the `.grant_access` method to the controller and its children. This method allows you to define the access rules.

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
This grants access to the `index` action for users with the `accountant` or `admin` role, and access to the `delete` action for only `admin` users.

You can also define controller-wide rules (without the `action` argument):

```rb
class Crm::BaseController < ApplicationController
  grant_access roles: :admin, :manager

  grant_access action: :dashboard, roles: :marketer
  def dashboard
    ...
  end
end

class InvoicesController < Crm::BaseControlle
  grant_access roles: :accountant
  def index
    ...
  end

  def delete
    ...
  end
end
```
This means that `admin` and `manager` have access to all actions inside `Crm::BaseController` and its children, while the `accountant` role has access only to actions in `InvoicesController` and its possible children. Users with the `marketer` role can see only the dashboard in this example.

Roles (as well as actions) can be omitted:

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

This allows everyone to access `OrdersController` and its children and the `index` action in `InvoicesController`.

If you've set the `must_have_roles` setting to `true`, then only the users with at least one role can have access. This setting can be useful if your requirements are so that users without roles are not allowed to see anything.

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
  grant_access action: :index, roles: :accountant, if: -> { current_user.passed_probationary_period? }
  def index
    ...
  end
end
```
You can pass a custom rule as an `if` argument. It can be a symbol (the method with the same name will be called) or a lambda.

Rules defined in children don't override parent rules but rather add to them:
```rb
class Crm::BaseController < ApplicationController
  grant_access roles: :admin
  ...
end

class InvoicesController < Crm::BaseControlle
  grant_access roles: :accountant
  ...
end
```
This means that `InvoicesController` is still accessible to `admin` but is also accessible to `accountant`.

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

- **Create an Issue**: If you've identified a problem or have a feature request, please create an issue on the gem's GitHub repository. Be sure to provide detailed information about the problem, including steps to reproduce it.
- **Contribute a Solution**: Found a fix for the issue or want to contribute to the project? Feel free to create a pull request with your changes.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
