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
      if block_given?
        begin
          yield
        ensure
          unlock
        end
      end
    end
    def unlock
      locked.clear
    end
  end

  module LockMeDown
    def lock_me_down(association)
      include DynamicDefaultScoping
      reflection = reflect_on_association association
      before_validation Proc.new {|m|
        return unless Lockdown.locked[association]
        m.send("#{association}=".to_sym, Lockdown.locked[association])
      }, :on => :create
      default_scope :locked_down, lambda {
        return {} unless Lockdown.locked[association]
        where({reflection.primary_key_name => Lockdown.locked[association].id})
      }
    end
  end
end
ActiveRecord::Base.extend Lockdown::LockMeDown
