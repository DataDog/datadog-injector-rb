# ruby-version-min: 1.8.7

Module::Import = lambda { |path| Module.new.tap { |m| m.module_eval(File.read(path), path) } }.call(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'mod', 'import.rb')))

test = Module::Import.import 'test'
test.autorun!

class TestMatrix < test::Test
  def flatten(val, ele={}, acc=[])
    case val
    when String, Symbol
      acc << ele.merge(:test => val)
    when Array
      val.each { |v| flatten(v, ele, acc) }
    when Hash
      val.each do |k, v|
        case k
        when Symbol, String
          flatten(v, ele.merge(k => true), acc)
        when Array
          k.each { |kv| flatten(v, ele.merge(kv), acc) }
        when Hash
          flatten(v, ele.merge(k), acc)
        end
      end
    end

    acc
  end

  def test_flatten
    assert_equal([{:test => 'foo'}]) { flatten('foo') }
    assert_equal([{:foo => true, :test => 'foo'}]) { flatten({:foo => 'foo'}) }

    assert_equal([{:foo => 'one', :test => 'bar'}]) { flatten({{:foo => 'one'} => 'bar'}) }
  # assert_equal({ :foo => :bar })   { flatten({ :foo => :bar }) }

    assert_equal([{:test => 'foo'}, {:test => 'bar'}]) { flatten(['foo', 'bar']) }

    assert_equal([{:test => 'foo'}, {:test => 'bar'}]) { flatten([['foo'], ['bar']]) }

    assert_equal([{:foo => true, :test => 'one'}, {:bar => true, :test => 'two'}]) { flatten([{ :foo => 'one' }, { :bar => 'two' }]) }

    assert_equal([{:foo => true, :test => 'one'}, {:foo => true, :test => 'two'}]) { flatten([{ :foo => ['one', 'two'] }]) }
  # assert_equal([{ :foo => 'one' }, { :bar => 'one' }]) {  flatten([{ [:foo, :bar] => 'one' }]) }
  # assert_equal([{ :foo => 'one' }, { :foo => 'two' }, { :bar => 'one' }, { :bar => 'two' }]) {  flatten([{ [:foo, :bar] => ['one', 'two'] }]) }

    assert_equal([{ :foo => 'a', :test => 'one' }, { :bar => 'b', :test => 'one' }]) {  flatten([{ [{:foo => 'a'}, {:bar => 'b'}] => 'one' }]) }
    assert_equal([{ :foo => 'a', :test => 'one' }, { :foo => 'a', :test => 'two' }, { :bar => 'b', :test => 'one' }, { :bar => 'b', :test => 'two' }]) {  flatten([{ [{:foo => 'a'}, {:bar => 'b'}] => ['one', 'two'] }]) }

  # assert_equal({ :foo => 'one' }) { flatten({ :foo => 'one' }) }
  # assert_equal({ :foo => 'one', :bar => 'two' }) { flatten({ :foo => 'one' } => { :bar => 'two' }) }
  # assert_equal({ :foo => 'one', :bar => 'two', :baz => 'three' }) { flatten({ :foo => 'one', :bar => 'two' } => { :baz => 'three' }) }
  end
end
