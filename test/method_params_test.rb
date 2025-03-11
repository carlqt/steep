require_relative "test_helper"

class MethodParamsTest < Minitest::Test
  include TestHelper
  include TypeErrorAssertions
  include FactoryHelper
  include SubtypingHelper
  include TypeConstructionHelper

  Namespace = RBS::Namespace

  MethodParams = Steep::TypeInference::MethodParams
  MethodArityMismatch = Steep::Diagnostic::Ruby::MethodArityMismatch
  MethodParameterMismatch = Steep::Diagnostic::Ruby::MethodParameterMismatch
  DifferentMethodParameterKind = Steep::Diagnostic::Ruby::DifferentMethodParameterKind

  def def_node(src)
    node = parse_ruby(src).node
    assert_equal :def, node.type
    node
  end

  def test_empty
    with_factory do
      node = def_node("def foo() end")
      method_type = parse_method_type("() -> void")

      params = MethodParams.build(node: node, method_type: method_type)

      assert_equal 0, params.size
    end
  end

  def test_required_positional_arg
    with_factory do
      node = def_node("def foo(x); end")

      MethodParams.build(node: node, method_type: parse_method_type("(Integer) -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::PositionalParameter.new(name: :x, type: parse_type("Integer"), node: params.args[0]),
          params[:x]
        )

        assert_empty params.errors
      end

      MethodParams.build(node: node, method_type: parse_method_type("(?Integer) -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::PositionalParameter.new(name: :x, type: parse_type("Integer"), node: params.args[0]),
          params[:x]
        )

        assert_any!(params.errors, size: 1) do |error|
          assert_instance_of MethodParameterMismatch, error
        end
      end

      MethodParams.build(node: node, method_type: parse_method_type("(*Integer) -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::PositionalParameter.new(name: :x, type: parse_type("Integer"), node: params.args[0]),
          params[:x]
        )

        assert_any!(params.errors, size: 1) do |error|
          assert_instance_of MethodParameterMismatch, error
        end
      end

      MethodParams.build(node: node, method_type: parse_method_type("() -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::PositionalParameter.new(name: :x, type: nil, node: params.args[0]),
          params[:x]
        )

        assert_any!(params.errors, size: 1) do |error|
          assert_instance_of MethodParameterMismatch, error
        end
      end
    end
  end

  def test_optional_positional_arg
    with_factory do
      node = def_node("def foo(x = 1); end")

      MethodParams.build(node: node, method_type: parse_method_type("(Integer) -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::PositionalParameter.new(name: :x, type: parse_type("Integer"), node: params.args[0]),
          params[:x]
        )

        assert_any!(params.errors, size: 1) do |error|
          assert_instance_of DifferentMethodParameterKind, error
        end
      end

      MethodParams.build(node: node, method_type: parse_method_type("(?Integer) -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::PositionalParameter.new(name: :x, type: parse_type("Integer"), node: params.args[0]),
          params[:x]
        )

        assert_empty params.errors
      end

      MethodParams.build(node: node, method_type: parse_method_type("(*Integer) -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::PositionalParameter.new(name: :x, type: parse_type("Integer"), node: params.args[0]),
          params[:x]
        )

        assert_any!(params.errors, size: 1) do |error|
          assert_instance_of DifferentMethodParameterKind, error
        end
      end

      MethodParams.build(node: node, method_type: parse_method_type("() -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::PositionalParameter.new(name: :x, type: nil, node: params.args[0]),
          params[:x]
        )

        assert_any!(params.errors, size: 1) do |error|
          assert_instance_of DifferentMethodParameterKind, error
        end
      end
    end
  end

  def test_rest_positional_arg
    with_factory do
      node = def_node("def foo(*x); end")

      MethodParams.build(node: node, method_type: parse_method_type("(Integer) -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::PositionalRestParameter.new(name: :x, type: parse_type("Integer"), node: params.args[0]),
          params[:x]
        )
        assert_equal parse_type("::Array[Integer]"), params[:x].var_type

        assert_any!(params.errors, size: 1) do |error|
          assert_instance_of DifferentMethodParameterKind, error
        end
      end

      MethodParams.build(node: node, method_type: parse_method_type("(?Integer) -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::PositionalRestParameter.new(name: :x, type: parse_type("Integer"), node: params.args[0]),
          params[:x]
        )

        assert_equal parse_type("::Array[Integer]"), params[:x].var_type

        assert_any!(params.errors, size: 1) do |error|
          assert_instance_of DifferentMethodParameterKind, error
        end
      end

      MethodParams.build(node: node, method_type: parse_method_type("(*Integer) -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::PositionalRestParameter.new(name: :x, type: parse_type("Integer"), node: params.args[0]),
          params[:x]
        )

        assert_equal parse_type("::Array[Integer]"), params[:x].var_type
      end

      MethodParams.build(node: node, method_type: parse_method_type("() -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::PositionalRestParameter.new(name: :x, type: nil, node: params.args[0]),
          params[:x]
        )

        assert_equal parse_type("::Array[untyped]"), params[:x].var_type
      end
    end
  end

  def test_no_positional_arg
    with_factory do
      node = def_node("def foo(); end")

      MethodParams.build(node: node, method_type: parse_method_type("(Integer) -> void")).tap do |params|
        assert_equal 0, params.size

        assert_any!(params.errors, size: 1) do |error|
          assert_instance_of MethodArityMismatch, error
        end
      end

      MethodParams.build(node: node, method_type: parse_method_type("(?Integer) -> void")).tap do |params|
        assert_equal 0, params.size

        assert_any!(params.errors, size: 1) do |error|
          assert_instance_of MethodArityMismatch, error
        end
      end

      MethodParams.build(node: node, method_type: parse_method_type("(*Integer) -> void")).tap do |params|
        assert_equal 0, params.size

        assert_any!(params.errors, size: 1) do |error|
          assert_instance_of MethodArityMismatch, error
        end
      end

      MethodParams.build(node: node, method_type: parse_method_type("() -> void")).tap do |params|
        assert_equal 0, params.size
        assert_empty params.errors
      end
    end
  end

  def test_required_keyword_arg
    with_factory do
      node = def_node("def foo(foo:); end")

      MethodParams.build(node: node, method_type: parse_method_type("(foo: String) -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::KeywordParameter.new(name: :foo, type: parse_type("String"), node: params.args[0]),
          params[:foo]
        )

        assert_empty params.errors
      end

      MethodParams.build(node: node, method_type: parse_method_type("(?foo: String) -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::KeywordParameter.new(name: :foo, type: parse_type("String"), node: params.args[0]),
          params[:foo]
        )

        assert_any!(params.errors) do |error|
          assert_instance_of MethodParameterMismatch, error
        end
      end

      MethodParams.build(node: node, method_type: parse_method_type("(**String) -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::KeywordParameter.new(name: :foo, type: parse_type("String"), node: params.args[0]),
          params[:foo]
        )

        assert_any!(params.errors) do |error|
          assert_instance_of MethodParameterMismatch, error
        end
      end

      MethodParams.build(node: node, method_type: parse_method_type("() -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::KeywordParameter.new(name: :foo, type: nil, node: params.args[0]),
          params[:foo]
        )

        assert_any!(params.errors) do |error|
          assert_instance_of MethodParameterMismatch, error
        end
      end
    end
  end

  def test_optional_keyword_arg
    with_factory do
      node = def_node("def foo(foo: ''); end")

      MethodParams.build(node: node, method_type: parse_method_type("(foo: String) -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::KeywordParameter.new(name: :foo, type: parse_type("String"), node: params.args[0]),
          params[:foo]
        )

        assert_any!(params.errors) do |error|
          assert_instance_of DifferentMethodParameterKind, error
        end
      end

      MethodParams.build(node: node, method_type: parse_method_type("(?foo: String) -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::KeywordParameter.new(name: :foo, type: parse_type("String"), node: params.args[0]),
          params[:foo]
        )

        assert_empty params.errors
      end

      MethodParams.build(node: node, method_type: parse_method_type("(**String) -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::KeywordParameter.new(name: :foo, type: parse_type("String"), node: params.args[0]),
          params[:foo]
        )

        assert_any!(params.errors) do |error|
          assert_instance_of DifferentMethodParameterKind, error
        end
      end

      MethodParams.build(node: node, method_type: parse_method_type("() -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::KeywordParameter.new(name: :foo, type: nil, node: params.args[0]),
          params[:foo]
        )

        assert_any!(params.errors) do |error|
          assert_instance_of DifferentMethodParameterKind, error
        end
      end
    end
  end

  def test_rest_keyword_arg
    with_factory do
      node = def_node("def foo(**foo); end")

      MethodParams.build(node: node, method_type: parse_method_type("(foo: String, bar: Integer, **Symbol) -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::KeywordRestParameter.new(
            name: :foo,
            type: parse_type("String | Integer | Symbol"),
            node: params.args[0]
          ),
          params[:foo]
        )

        assert_equal parse_type("::Hash[::Symbol, String | Integer | Symbol]"), params[:foo].var_type

        assert_any!(params.errors, size: 1) do |error|
          assert_instance_of DifferentMethodParameterKind, error
        end
      end

      MethodParams.build(node: node, method_type: parse_method_type("(?foo: String) -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::KeywordRestParameter.new(
            name: :foo,
            type: parse_type("String"),
            node: params.args[0]
          ),
          params[:foo]
        )

        assert_any!(params.errors, size: 1) do |error|
          assert_instance_of DifferentMethodParameterKind, error
        end
      end

      MethodParams.build(node: node, method_type: parse_method_type("(**Symbol) -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::KeywordRestParameter.new(
            name: :foo,
            type: parse_type("Symbol"),
            node: params.args[0]
          ),
          params[:foo]
        )

        assert_equal parse_type("::Hash[::Symbol, Symbol]"), params[:foo].var_type

        assert_empty(params.errors)
      end

      MethodParams.build(node: node, method_type: parse_method_type("() -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::KeywordRestParameter.new(name: :foo, type: nil, node: params.args[0]),
          params[:foo]
        )

        assert_equal parse_type("::Hash[::Symbol, untyped]"), params[:foo].var_type

        assert_any!(params.errors, size: 1) do |error|
          assert_instance_of DifferentMethodParameterKind, error
        end
      end
    end
  end

  def test_no_keyword_arg
    with_factory do
      node = def_node("def foo(); end")

      MethodParams.build(node: node, method_type: parse_method_type("(foo: String) -> void")).tap do |params|
        assert_equal 0, params.size

        assert_any!(params.errors, size: 1) do |error|
          assert_instance_of MethodArityMismatch, error
        end
      end

      MethodParams.build(node: node, method_type: parse_method_type("(?foo: Symbol) -> void")).tap do |params|
        assert_equal 0, params.size

        assert_any!(params.errors, size: 1) do |error|
          assert_instance_of MethodArityMismatch, error
        end
      end

      MethodParams.build(node: node, method_type: parse_method_type("(**Symbol) -> void")).tap do |params|
        assert_equal 0, params.size

        assert_any!(params.errors, size: 1) do |error|
          assert_instance_of MethodArityMismatch, error
        end
      end

      MethodParams.build(node: node, method_type: parse_method_type("() -> void")).tap do |params|
        assert_equal 0, params.size
        assert_empty params.errors
      end
    end
  end

  def test_block_arg
    with_factory do
      node = def_node("def foo(&block); end")

      MethodParams.build(node: node, method_type: parse_method_type("() { () -> void } -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::BlockParameter.new(
            name: :block,
            type: parse_type("^() -> void").type,
            node: params.args[0],
            optional: false,
            self_type: nil
          ),
          params[:block]
        )

        assert_equal parse_type("^() -> void"), params[:block].var_type

        assert_empty params.errors
      end

      MethodParams.build(node: node, method_type: parse_method_type("() { () [self: self] -> void } -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::BlockParameter.new(
            name: :block,
            type: parse_type("^() -> void").type,
            node: params.args[0],
            optional: false,
            self_type: parse_type("self")
          ),
          params[:block]
        )

        assert_equal parse_type("^() [self: self] -> void"), params[:block].var_type

        assert_empty params.errors
      end

      MethodParams.build(node: node, method_type: parse_method_type("() ?{ () -> void } -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::BlockParameter.new(
            name: :block,
            type: parse_type("^() -> void").type,
            node: params.args[0],
            optional: true,
            self_type: nil
          ),
          params[:block]
        )

        assert_equal parse_type("^() -> void | nil"), params[:block].var_type

        assert_empty params.errors
      end

      MethodParams.build(node: node, method_type: parse_method_type("() -> void")).tap do |params|
        assert_equal 1, params.size

        assert_equal(
          MethodParams::BlockParameter.new(
            name: :block,
            type: nil,
            node: params.args[0],
            optional: false,
            self_type: nil
          ),
          params[:block]
        )

        assert_equal parse_type("nil"), params[:block].var_type

        assert_empty params.errors
      end
    end
  end

  def test_forward_arg1
    with_factory do
      node = def_node("def foo(...); end")

      MethodParams.build(node: node, method_type: parse_method_type("(Integer) -> void")).tap do |params|
        assert_equal "(Integer)", params.forward_arg_type[0].to_s
        assert_nil params.forward_arg_type[1]
      end

      MethodParams.build(node: node, method_type: parse_method_type("(A, ?B, *C, x: D, ?y: E, **F) -> void")).tap do |params|
        assert_equal "(A, ?B, *C, x: D, ?y: E, **F)", params.forward_arg_type[0].to_s
        assert_nil params.forward_arg_type[1]
      end

      MethodParams.build(node: node, method_type: parse_method_type("() { () -> void } -> void")).tap do |params|
        assert_equal "()", params.forward_arg_type[0].to_s
        assert_equal "{ () -> void }", params.forward_arg_type[1].to_s
      end

      MethodParams.build(node: node, method_type: parse_method_type("(?) -> void")).tap do |params|
        assert_equal true, params.forward_arg_type
      end
    end
  end

  def test_forward_arg2
    with_factory do
      node = def_node("def foo(x, ...); end")

      MethodParams.build(node: node, method_type: parse_method_type("(Integer) -> void")).tap do |params|
        assert_equal "()", params.forward_arg_type[0].to_s
        assert_nil params.forward_arg_type[1]
      end

      MethodParams.build(node: node, method_type: parse_method_type("(A, ?B, *C, x: D, ?y: E, **F) -> void")).tap do |params|
        assert_equal "(?B, *C, x: D, ?y: E, **F)", params.forward_arg_type[0].to_s
        assert_nil params.forward_arg_type[1]
      end

      MethodParams.build(node: node, method_type: parse_method_type("(untyped) { () -> void } -> void")).tap do |params|
        assert_equal "()", params.forward_arg_type[0].to_s
        assert_equal "{ () -> void }", params.forward_arg_type[1].to_s
      end
    end
  end
end
