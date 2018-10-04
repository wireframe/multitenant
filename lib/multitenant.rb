require 'active_record'

# Multitenant: making cross tenant data leaks a thing of the past...since 2011
module Multitenant
  class AccessException < RuntimeError
  end
  
  class << self
    attr_accessor :current_tenant

    # execute a block scoped to the current tenant
    # unsets the current tenant after execution
    def with_tenant(tenant, &block)
      previous_tenant = Multitenant.current_tenant
      Multitenant.current_tenant = tenant
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
        tenant = m.send "#{association}"
        if tenant.nil? then
          m.send "#{association}=".to_sym, Multitenant.current_tenant
        elsif tenant.id != Multitenant.current_tenant.id
          raise AccessException, "Can't create a new instance for tenant #{tenant.id} while Multitenant.current_tenant is #{Multitenant.current_tenant.id}"
        end          
      }, :on => :create
      
      # Prevent updating objects to a different tenant
      before_save Proc.new {|m|
        return unless Multitenant.current_tenant
        tenant = m.send "#{association}".to_sym
        raise AccessException, "Trying to update object in to tenant #{tenant.id} while in current_tenant #{Multitenant.current_tenant.id}" unless tenant.id == Multitenant.current_tenant.id
      }
      
      default_scope lambda {
        where({reflection.foreign_key => Multitenant.current_tenant.id}) if Multitenant.current_tenant
      }
    end
  end
end
ActiveRecord::Base.extend Multitenant::ActiveRecordExtensions
