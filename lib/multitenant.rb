require 'active_record'

# Multitenant: making cross tenant data leaks a thing of the past...since 2011
module Multitenant
  class << self
    attr_accessor :current_tenant

    # execute a block scoped to the current tenant
    # unsets the current tenant after execution
    # @param [Object] tenant the new current tenant
    # @param [Hash] options
    # @option options [Symbol] :became_current_tenant_method (:became_current_tenant) name of the method to call on tenant after it became the current one (and before the block is run)
    def with_tenant(tenant, options={}, &block)
      options[:became_current_tenant_method] ||= :became_current_tenant
      previous_tenant = Multitenant.current_tenant
      Multitenant.current_tenant = tenant
      tenant.send(options[:became_current_tenant_method]) if tenant.respond_to?(options[:became_current_tenant_method])
      yield
    ensure
      Multitenant.current_tenant = previous_tenant
    end
  end

  module ActiveRecordExtensions
    # configure the current model to automatically query and populate objects based on the current tenant
    # see Multitenant#current_tenant
    def belongs_to_multitenant(association = :tenant)
      reflection = reflect_on_association association
      before_validation Proc.new {|m|
        return unless Multitenant.current_tenant
        m.send "#{association}=".to_sym, Multitenant.current_tenant
      }, :on => :create
      default_scope lambda {
        where({reflection.foreign_key => Multitenant.current_tenant.id}) if Multitenant.current_tenant
      }
    end
  end
end
ActiveRecord::Base.extend Multitenant::ActiveRecordExtensions
