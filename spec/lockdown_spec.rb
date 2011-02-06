require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

ActiveRecord::Schema.define(:version => 1) do
  create_table :companies, :force => true do |t|
    t.column :name, :string
  end

  create_table :users, :force => true do |t|
    t.column :name, :string
    t.column :company_id, :integer
  end
end

class Company < ActiveRecord::Base
  has_many :users
end

class User < ActiveRecord::Base
  belongs_to :company
  lock_me_down :company
end

describe "Lockdown" do
  describe 'Lockdown.locked' do
    it { Lockdown.locked.should == {} }
  end

  describe 'Lockdown.lock' do
    before do
      @company = Company.create!(:name => 'foo')
      Lockdown.lock :company => @company
    end
    it { Lockdown.locked[:company].should == @company }
  end

  describe 'Lockdown.unlock' do
    before do
      Lockdown.lock :foo => 'test'
      Lockdown.unlock
    end
    it { Lockdown.locked.should == {} }
  end

  describe 'User.all when locked to one company' do
    before do
      @company = Company.create!(:name => 'foo')
      @company2 = Company.create!(:name => 'bar')

      @user = @company.users.create! :name => 'bob'
      @user2 = @company2.users.create! :name => 'tim'
      Lockdown.lock :company => @company
      @users = User.all
    end
    it { @users.length.should == 1 }
    it { @users.should == [@user] }
  end


  describe 'Lockdown.lock with block' do
    it 'unlocks after block runs'
  end

  describe 'Lockdown.lock with block that raises error' do
    it 'unlocks after block runs'
    it 'bubbles exception'
  end

end
