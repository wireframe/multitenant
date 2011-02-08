require 'active_record'
require 'active_support/all'
require 'dynamic_default_scoping'

module Multitenant
  class << self
    attr_accessor :current_tenant

    # execute a block scoped to the current tenant
    # unsets the current tenant after execution
    def with_tenant(tenant, &block)
      Multitenant.current_tenant = tenant
      yield
    ensure
      Multitenant.current_tenant = nil
    end
  end

  module ActiveRecordExtensions
    def belongs_to_tenant(association = :tenant)
      include DynamicDefaultScoping
      reflection = reflect_on_association association
      before_validation Proc.new {|m|
        return unless Multitenant.current_tenant
        m.send "#{association}=".to_sym, Multitenant.current_tenant
      }, :on => :create
      default_scope :scoped_to_tenant, lambda {
        return {} unless Multitenant.current_tenant
        where({reflection.primary_key_name => Multitenant.current_tenant.id})
      }
    end
  end
end
ActiveRecord::Base.extend Multitenant::ActiveRecordExtensions
