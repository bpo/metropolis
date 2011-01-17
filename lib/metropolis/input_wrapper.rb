# -*- encoding: binary -*-

class Metropolis::InputWrapper
  include Metropolis::Constants

  def initialize(env)
    @input = env[Rack_Input]
    env[Rack_Input] = self
  end

  def read(*args)
    args.empty? and return read_all
    ni
  end

  def ni(*args)
    raise NotImplementedError
  end

  alias gets ni
  alias each ni
  alias rewind ni
end
