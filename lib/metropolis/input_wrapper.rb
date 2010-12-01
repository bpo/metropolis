# -*- encoding: binary -*-

class Metropolis::InputWrapper
  def initialize(env)
    @input = env["rack.input"]
    env["rack.input"] = self
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
