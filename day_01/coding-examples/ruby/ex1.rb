class Ex1
  def run
    result = add2(2, 4)
    show_result(result)
  end

private

  def add2(n1, n2) 
    n1 + n2
  end

  def show_result(result)
    p result
  end
  # could  also be written like so:
  # def show_result(result); p result; end
end

# this will be executed since it is not enclosed in a function or other definition when the file is loaded
instance = Ex1.new
instance.run
