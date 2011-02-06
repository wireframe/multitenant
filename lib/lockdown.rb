require 'active_record'

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
    def lock_me_down
      scope :lockdown, lambda {
        return {} unless Lockdown.locked[:company]
        where({:company_id => Lockdown.locked[:company].id}) 
      }
    end
  end
end
ActiveRecord::Base.extend Lockdown::LockMeDown
