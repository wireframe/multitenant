require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

ActiveRecord::Schema.define(:version => 1) do
  create_table :companies, :force => true do |t|
    t.column :name, :string
  end

  create_table :users, :force => true do |t|
    t.column :name, :string
  end
end

class Company < ActiveRecord::Base; end

describe "Lockdown" do
  describe 'Lockdown.lock' do
    before do
      Lockdown.lock :company => Company.create!(:name => 'foo')
    end
  end

  describe 'Lockdown.lock with block' do
    it 'unlocks after block runs'
  end

  describe 'Lockdown.lock with block that raises error' do
    it 'unlocks after block runs'
    it 'bubbles exception'
  end

end
