require 'spec_helper'

ActiveRecord::Schema.define(:version => 1) do
  create_table :companies, :force => true do |t|
    t.column :name, :string
  end

  create_table :users, :force => true do |t|
    t.column :name, :string
    t.column :company_id, :integer
  end


  create_table :tenants, :force => true do |t|
    t.column :name, :string
  end

  create_table :items, :force => true do |t|
    t.column :name, :string
    t.column :tenant_id, :integer
  end
end

class Company < ActiveRecord::Base
  has_many :users
  attr_accessor :now_is_current_tenant

  def became_current_tenant
    self.now_is_current_tenant = true
  end
end
class User < ActiveRecord::Base
  belongs_to :company
  belongs_to_multitenant :company
end

class Tenant < ActiveRecord::Base
  has_many :items
end
class Item < ActiveRecord::Base
  belongs_to :tenant
  belongs_to_multitenant
end

describe Multitenant do
  after { Multitenant.current_tenant = nil }

  describe 'Multitenant.current_tenant' do
    before do
      @company = Company.create!(:name => 'foo')
      @company.now_is_current_tenant.should == nil
      Multitenant.current_tenant = @company
    end
    it { Multitenant.current_tenant.should == @company }
    it { @company.now_is_current_tenant.should == true }
  end

  describe 'Multitenant.with_tenant block' do
    before do
      @executed = false
      Multitenant.with_tenant :foo do
        Multitenant.current_tenant.should == :foo
        @executed = true
      end
    end
    it 'clears current_tenant after block runs' do
      Multitenant.current_tenant.should == nil
    end
    it 'yields the block' do
      @executed.should == true
    end
  end

  describe 'Multitenant.with_tenant block with a previous tenant' do
    before do
      @previous = :whatever
      Multitenant.current_tenant = @previous
      @executed = false
      Multitenant.with_tenant :foo do
        Multitenant.current_tenant.should == :foo
        @executed = true
      end
    end
    it 'resets current_tenant after block runs' do
      Multitenant.current_tenant.should == @previous
    end
    it 'yields the block' do
      @executed.should == true
    end
  end

  describe 'Multitenant.with_tenant block that raises error' do
    before do
      @executed = false
      lambda {
        Multitenant.with_tenant :foo do
          @executed = true
          raise 'expected error'
        end
      }.should raise_error('expected error')
    end
    it 'clears current_tenant after block runs' do
      Multitenant.current_tenant.should == nil
    end
    it 'yields the block' do
      @executed.should == true
    end
  end

  describe 'User.all when current_tenant is set' do
    before do
      @company = Company.create!(:name => 'foo')
      @company.now_is_current_tenant.should == nil
      @company2 = Company.create!(:name => 'bar')

      @user = @company.users.create! :name => 'bob'
      @user2 = @company2.users.create! :name => 'tim'
      Multitenant.with_tenant @company do
        @users = User.all
      end
    end
    it { @users.length.should == 1 }
    it { @users.should == [@user] }
    it { @company.now_is_current_tenant.should == true }
  end

  describe 'Item.all when current_tenant is set' do
    before do
      @tenant = Tenant.create!(:name => 'foo')
      @tenant2 = Tenant.create!(:name => 'bar')

      @item = @tenant.items.create! :name => 'baz'
      @item2 = @tenant2.items.create! :name => 'booz'
      Multitenant.with_tenant @tenant do
        @items = Item.all
      end
    end
    it { @items.length.should == 1 }
    it { @items.should == [@item] }
  end


  describe 'creating new object when current_tenant is set' do
    before do
      @company = Company.create! :name => 'foo'
      Multitenant.with_tenant @company do
        @user = User.create! :name => 'jimmy'
      end
    end
    it 'should auto_populate the company' do
      @user.company_id.should == @company.id
    end
  end
end
