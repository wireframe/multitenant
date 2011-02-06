require 'active_record'
require 'active_support/all'
require 'dynamic_default_scoping'

module Lockdown
  class << self
    def locked
      @@locked ||= {}
      @@locked
    end
    def lock(options = {}, &block)
      locked.merge! options
    end
    def unlock(*args)
    end
  end

  module LockMeDown
    def lock_me_down(association)
      include DynamicDefaultScoping
      default_scope :locked_down, lambda {
        return {} unless Lockdown.locked[association]
        where({"#{association}_id" => Lockdown.locked[association].id}) 
      }
    end
  end
end
ActiveRecord::Base.extend Lockdown::LockMeDown
