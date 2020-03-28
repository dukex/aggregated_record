# AggregatedRecord

Helping you to build record from a event sourcing project using https://railseventstore.org/.

This project is a oppinated syntax sugar to AggregateRoot, explained here [Event Sourcing with AggregateRoot](https://railseventstore.org/docs/app/)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aggregated_record'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aggregated_record

## Usage

*Note: This documentation use a namespace to hold all model events, handlers and data, you can structure in your way.

### Define your models and events

The model is defined by 3 sections: Attributes, publishers or actions, and handlers.

By default a model has the follow attributes:
- `:id`
- `:stream_name`
- `:created_at`
- `:updated_at`

And the follow publishers:
- `create!`
- `update!`

And the follow handlers:
- `apply_created`
- `apply_updated`

Let's to define an example `Post` model.

```
class Post < AggregatedRecord
  Created = Class.new(RubyEventStore::Event)
  Updated = Class.new(RubyEventStore::Event)
  Deleted = Class.new(RubyEventStore::Event)
  VisibilityChanged = Class.new(RubyEventStore::Event)

  created_with Post::Created
  updated_with Post::Updated

  # ATTRIBUTES
  attr_reader :title, :body, :visibility, :deleted_at

  # PUBLISHERS

  def visibility=(new_visibility)
    publish(Post::VisibilityChanged, visibility: new_visibility)
  end

  def delete!
    publish(Post::Deleted)
  end

  # HANDLERS
  on Post::VisibilityChanged do |event|
    apply_updated(event)
  end

  on Post::Deleted do |event|
    @deleted_at = event.metadata[:timestamp]
  end
end
```

### Publish events

```ruby
# Creating the post
post.create!(id: 'my-awesome-post', title: 'My Awesome Post', body: 'lorem ipsum', visibility: :private)
post.title # 'My Awesome Post'
post.body # 'lorem ipsum'
post.visibility # :private
post.created_at # Time...
post.updated_at # Time...

# Update using the defined method
post.visibility = :public
post.visibility # :public

# Update using `update!` method
post.update!(title: 'My Post')
post.title # My Post'

# Saving the unpublished events in model
post.save
```

### Link models

To create relation between models your can link the creation event of a model to another.

Per example, given the last definition of `Post`, let's to create a `Comment` model.

```ruby
class Comment < AggregatedRecord
  Created = Class.new(RubyEventStore::Event)
  Updated = Class.new(RubyEventStore::Event)

  created_with Comment::Created
  updated_with Comment::Updated

  attr_reader :body
end
```

Linking the post with the comments, using `link!` model method

```ruby
post = Post.find('my-post')
comment = Comment.create!(id: '21345674321', body: 'Nice post bro')
post.link!(comment)
```

Now you can get all comments from post using `in` method.

```ruby
post = Post.find('my-post')
comments = Comment.in(post.stream_name)
comments.count # 1
comments.first.id # 21345674321
comments.first.body # 'Nice post bro'
```
## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dukex/aggregated_record. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AggregatedRecord project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/dukex/aggregated_record/blob/master/CODE_OF_CONDUCT.md).
