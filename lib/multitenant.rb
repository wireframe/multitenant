require 'active_record'

# Multitenant: making cross tenant data leaks a thing of the past...since 2011
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
    # configure the current model to automatically query and populate objects based on the current tenant
    # see Multitenant#current_tenant
    def belongs_to_multitenant(association = :tenant)
      reflection      = reflect_on_association association
      multitenantable = -> { Multitenant.current_tenant && Multitenant.current_tenant.class == reflection.klass }

      before_validation Proc.new {|m|
        m.send("#{association}=".to_sym, Multitenant.current_tenant) if multitenantable.call
      }, :on => :create
      default_scope lambda {
        where({reflection.foreign_key => Multitenant.current_tenant.id}) if multitenantable.call
      }
    end
  end
end
ActiveRecord::Base.extend Multitenant::ActiveRecordExtensions
