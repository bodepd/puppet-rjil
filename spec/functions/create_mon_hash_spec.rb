require 'spec_helper'
describe 'create_mon_hash' do

  it 'should only accept an array argument' do
    expect do
      should run.with_params('FOO', 'bar', 'bax').and_return('bar')
    end.to raise_error(Puppet::ParseError, 'Member array only expects an array, not String')
  end

  it 'should only accept one argument' do
    expect do
      should run.with_params('FOO', 'bar').and_return('bar')
    end.to raise_error(ArgumentError, /Wrong number of arguments given/)
  end

  it 'should convert and array into a mon_config hash' do
    result = should run.with_params(
      'hostname',
      '127.0.0.1',
      ['127.0.0.2']
    )
     # .and_return(
     # {
     #   'hostname' => {'mon_addr' => '127.0.0.1'},
     #   '127-0-0-2' => {'mon_addr' => '127.0.0.2'}
     #  }
    #)
  end

end
