require_relative "test_helper"

class TypingTest < Minitest::Test
  Typing = Steep::Typing
  TypeEnv = Steep::TypeInference::TypeEnv
  Context = Steep::TypeInference::Context

  include TestHelper
  include FactoryHelper

  # @rbs skip
  include Minitest::Hooks

  def around
    with_factory do
      super
    end
  end

  def context
    resolver = RBS::Resolver::ConstantResolver.new(builder: factory.definition_builder)
    constant_env = Steep::TypeInference::ConstantEnv.new(factory: factory, context: nil, resolver: resolver)
    @context ||= Context.new(
      method_context: nil,
      block_context: nil,
      break_context: nil,
      module_context: nil,
      self_type: parse_type("::Object"),
      type_env: TypeEnv.new(constant_env),
      call_context: Steep::TypeInference::MethodCall::TopLevelContext.new,
      variable_context: Context::TypeVariableContext.empty
    )
  end

  def test_1
    source = parse_ruby("123")
    node = source.node

    typing = Steep::Typing.new(source: source, root_context: context, cursor: nil)

    type = parse_type("::String")

    typing.add_typing(node, type, context)

    assert_equal type, typing.type_of(node: node)
  end

  def test_new_child_with_save
    source = parse_ruby("123 + 456")
    node = source.node

    typing = Steep::Typing.new(source: source, root_context: context, cursor: nil)

    type = parse_type("::String")

    typing.add_typing(node, type, context)

    typing.new_child() do |typing_|
      assert_equal type, typing.type_of(node: node)

      typing_.add_typing(node.children[0], type, context)
      typing_.add_typing(node.children[1], type, context)

      typing_.save!
    end

    assert_equal type, typing.type_of(node: node)
    assert_equal type, typing.type_of(node: node.children[0])
    assert_equal type, typing.type_of(node: node.children[1])
  end

  def test_new_child_without_save
    source = parse_ruby("123 + 456")
    node = source.node

    typing = Steep::Typing.new(source: source, root_context: context, cursor: nil)

    type = parse_type("::String")

    typing.add_typing(node, type, context)

    typing.new_child() do |typing_|
      assert_equal type, typing.type_of(node: node)

      typing_.add_typing(node.children[0], type, context)
      typing_.add_typing(node.children[1], type, context)
    end

    assert_equal type, typing.type_of(node: node)
    assert_raises { typing.type_of(node: node.children[0]) }
    assert_raises { typing.type_of(node: node.children[1]) }
  end

  def test_new_child_check
    source = parse_ruby("123 + 456")
    node = source.node

    typing = Steep::Typing.new(source: source, root_context: context, cursor: nil)

    type = parse_type("::String")

    typing.add_typing(node, type, context)

    child1 = typing.new_child()
    child1.add_typing(node.children[0], type, context)

    typing.add_typing(node.children[1], type, context)

    assert_raises do
      child1.save!
    end
  end

  def test_new_child_check2
    source = parse_ruby("123 + 456")
    node = source.node

    typing = Steep::Typing.new(source: source, root_context: context, cursor: nil)

    type = parse_type("::String")

    child1 = typing.new_child()
    child1.add_typing(node.children[0], type, context)

    child2 = typing.new_child()
    child2.add_typing(node.children[1], type, context)

    child1.save!

    assert_raises do
      child2.save!
    end
  end
end
