[![Build Status](https://travis-ci.org/wireframe/multitenant.png?branch=master)](https://travis-ci.org/wireframe/multitenant)

# Multitenant

When building multitenant applications, never let an unscoped Model.all
accidentally leak data to an unintended audience.

## Usage

```ruby
class User < ActiveRecord::Base
  belongs_to :tenant
  belongs_to_multitenant
  
  validates :email, uniqueness: true                    # application-wide uniqueness
  validates :alias, uniqueness: { scope: :tenant_id }   # tenant-wide uniqueness
end

Multitenant.with_tenant current_tenant do
  # queries within this block are automatically
  # scoped to the current tenant
  User.all

  # new objects created within this block are automatically
  # assigned to the current tenant
  User.create :name => 'Bob'
end
```

## Features

*   Rails 3 compatible
*   Restrict database queries to only lookup objects for the current tenant
*   Auto assign newly created objects to the current tenant


## Contributing

*   Check out the latest master to make sure the feature hasn't been
    implemented or the bug hasn't been fixed yet
*   Check out the issue tracker to make sure someone already hasn't requested
    it and/or contributed it
*   Fork the project
*   Start a feature/bugfix branch
*   Commit and push until you are happy with your contribution
*   Make sure to add tests for it. This is important so I don't break it in a
    future version unintentionally.
*   Please try not to mess with the Rakefile, version, or history. If you want
    to have your own version, or is otherwise necessary, that is fine, but
    please isolate to its own commit so I can cherry-pick around it.


## Credits

Thanks to Lars Klevan for inspiring this project.

## Copyright

Copyright (c) 2011 Ryan Sonnek. See LICENSE.txt for further details.

