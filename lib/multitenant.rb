require 'active_record'

# Multitenant: making cross tenant data leaks a thing of the past...since 2011
module Multitenant
  class AccessException < RuntimeError
  end
  
  class << self
    CURRENT_TENANT = 'Multitenant.current_tenant'.freeze
    ALLOW_DANGEROUS = 'Multitenant.allow_dangerous_cross_tenants'.freeze
    EXTRA_TENANT_IDS = 'Multitenant.extra_tenant_ids'.freeze

    def current_tenant
      Thread.current[CURRENT_TENANT]
    end

    def current_tenant=(value)
      Thread.current[CURRENT_TENANT] = value
    end

    def allow_dangerous_cross_tenants
      Thread.current[ALLOW_DANGEROUS]
    end

    def allow_dangerous_cross_tenants=(value)
      Thread.current[ALLOW_DANGEROUS] = value
    end

    def extra_tenant_ids
      Thread.current[EXTRA_TENANT_IDS]
    end

    def extra_tenant_ids=(value)
      Thread.current[EXTRA_TENANT_IDS] = value
    end

    # execute a block scoped to the current tenant
    # unsets the current tenant after execution
    def with_tenant(tenant, options = {}, &block)
      previous_tenant = Multitenant.current_tenant
      Multitenant.current_tenant = tenant
      previous_extra_tenant_ids = Multitenant.extra_tenant_ids
      Multitenant.extra_tenant_ids = options[:extra_tenant_ids] if options[:extra_tenant_ids]
      yield
    ensure
      Multitenant.current_tenant = previous_tenant
      Multitenant.extra_tenant_ids = previous_extra_tenant_ids
    end

    def dangerous_cross_tenants(&block)
      previous_value = Multitenant.allow_dangerous_cross_tenants
      Multitenant.allow_dangerous_cross_tenants = true
      Multitenant.with_tenant(nil) do
        yield
      end
    ensure
      Multitenant.allow_dangerous_cross_tenants = previous_value
    end
  end

  module ActiveRecordExtensions
    # configure the current model to automatically query and populate objects based on the current tenant
    # see Multitenant#current_tenant
    def belongs_to_multitenant(association = :tenant)
      reflection = reflect_on_association association
      association_key = reflection.foreign_key.to_s
      before_validation Proc.new {|m|
        next unless Multitenant.current_tenant
        tenant_id = m.send association_key
        if tenant_id.nil? then
          m.send "#{association}=".to_sym, Multitenant.current_tenant
        elsif tenant_id != Multitenant.current_tenant.id
          raise AccessException, "Can't create a new instance for tenant #{tenant_id} while Multitenant.current_tenant is #{Multitenant.current_tenant.id}"
        end          
      }, :on => :create
      
      # Prevent updating objects to a different tenant
      before_save Proc.new {|m|
        next unless Multitenant.current_tenant
        tenant_id = m.send association_key.to_sym
        raise AccessException, "Trying to update object in to tenant #{tenant_id} while in current_tenant #{Multitenant.current_tenant.id}" unless tenant_id == Multitenant.current_tenant.id
      }
      
      default_scope -> () {
        if Multitenant.current_tenant.present?
          tenant_ids = Multitenant.extra_tenant_ids.present? ? Multitenant.extra_tenant_ids + [Multitenant.current_tenant.id] : Multitenant.current_tenant.id
          where({association_key => tenant_ids})
        elsif Multitenant.allow_dangerous_cross_tenants == true
          next nil # do nothing
        else
          begin
            # log only requests to app servers
            if Thread.current[:request_path].present?
              $logger.info({
                message: 'multitenant account is not defined',
                request_path: Thread.current[:request_path],
                current_queue: Thread.current[:current_queue],
                klass: self.to_s
              })
            elsif Thread.current[:current_queue].present?
              #log once in 100 to make less logs
              $logger.info({
                message: '[sidekiq] multitenant account is not defined',
                current_queue: Thread.current[:current_queue],
                klass: self.to_s
              })
              raise SidekiqMultitenantError
            end
            next nil # do nothing
          rescue SidekiqMultitenantError => e
            raise e
          rescue StandardError => e
            next nil # do nothing
          end
        end
      }
    end
  end
end
ActiveRecord::Base.extend Multitenant::ActiveRecordExtensions

class SidekiqMultitenantError < StandardError
  def message
    '[sidekiq] multitenant account is not defined'
  end
end