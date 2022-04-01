require_relative "test_helper"

class TypeEnvTest < Minitest::Test
  include Steep

  include TestHelper
  include FactoryHelper
  include SubtypingHelper

  ConstantEnv = TypeInference::ConstantEnv
  TypeEnv = TypeInference::TypeEnv

  def test_ivar_without_annotation
    with_checker do |checker|
      const_env = ConstantEnv.new(factory: checker.factory, context: [], resolver: RBS::Resolver::ConstantResolver.new(builder: checker.factory.definition_builder))
      type_env = TypeEnv.new(subtyping: checker, const_env: const_env)

      # If no annotation is given to ivar, assign yields the block with nil and returns `any`
      yield_self do
        ivar_type = type_env.assign(
          ivar: :"@x",
          type: AST::Types::Name.new_instance(name: "::String"),
          self_type: parse_type("self"),
          instance_type: parse_type("instance"),
          class_type: parse_type("class")
        ) { |error| assert_nil error }
        assert_instance_of AST::Types::Any, ivar_type
      end

      # If no annotation is given to ivar, get yields the block and returns `any`
      yield_self do
        ivar_type = type_env.get(ivar: :"@x") { |error| assert_nil error }
        assert_instance_of AST::Types::Any, ivar_type
      end
    end
  end

  def test_ivar_with_annotation
    with_checker do |checker|
      const_env = ConstantEnv.new(factory: checker.factory, context: [], resolver: RBS::Resolver::ConstantResolver.new(builder: checker.factory.definition_builder))
      type_env = TypeEnv.new(subtyping: checker, const_env: const_env)

      type_env.set(ivar: :"@x", type: AST::Types::Name.new_instance(name: "::Numeric"))

      # If annotation is given, get returns the type
      yield_self do
        ivar_type = type_env.get(ivar: :"@x")
        assert_equal AST::Types::Name.new_instance(name: "::Numeric"), ivar_type
      end

      # If annotation is given and assigned type is compatible with that, assign returns annotated type, no yield
      yield_self do
        ivar_type = type_env.assign(
          ivar: :"@x",
          type: AST::Types::Name.new_instance(name: "::Integer"),
          self_type: parse_type("self"),
          instance_type: parse_type("instance"),
          class_type: parse_type("class")
        ) do |_|
          raise
        end
        assert_equal AST::Types::Name.new_instance(name: "::Numeric"), ivar_type
      end

      # If annotation is given and assigned type is incompatible with that, assign returns annotated type and yield an failure result
      yield_self do
        ivar_type = type_env.assign(
          ivar: :"@x",
          type: AST::Types::Name.new_instance(name: "::String"),
          self_type: parse_type("self"),
          instance_type: parse_type("instance"),
          class_type: parse_type("class")
        ) do |error|
          assert_predicate error, :failure?
        end
        assert_equal AST::Types::Name.new_instance(name: "::Numeric"), ivar_type
      end
    end
  end

  def test_gvar_without_annotation
    with_checker do |checker|
      const_env = ConstantEnv.new(factory: checker.factory, context: [], resolver: RBS::Resolver::ConstantResolver.new(builder: checker.factory.definition_builder))
      type_env = TypeEnv.new(subtyping: checker, const_env: const_env)

      # If no annotation is given to ivar, assign yields the block with nil and returns `any`
      yield_self do
        type = type_env.assign(
          gvar: :"$x",
          type: AST::Types::Name.new_instance(name: "::String"),
          self_type: parse_type("self"),
          instance_type: parse_type("instance"),
          class_type: parse_type("class")
        ) { |error| assert_nil error }
        assert_instance_of AST::Types::Any, type
      end

      # If no annotation is given to ivar, get yields the block and returns `any`
      yield_self do
        type = type_env.get(gvar: :"$x") { |error| assert_nil error }
        assert_instance_of AST::Types::Any, type
      end
    end
  end

  def test_gvar_with_annotation
    with_checker do |checker|
      const_env = ConstantEnv.new(factory: checker.factory, context: [], resolver: RBS::Resolver::ConstantResolver.new(builder: checker.factory.definition_builder))
      type_env = TypeEnv.new(subtyping: checker, const_env: const_env)

      type_env.set(gvar: :"$x", type: AST::Types::Name.new_instance(name: "::Numeric"))

      # If annotation is given, get returns the type
      yield_self do
        type = type_env.get(gvar: :"$x")
        assert_equal AST::Types::Name.new_instance(name: "::Numeric"), type
      end

      # If annotation is given and assigned type is compatible with that, assign returns annotated type, no yield
      yield_self do
        type = type_env.assign(
          gvar: :"$x",
          type: AST::Types::Name.new_instance(name: "::Integer"),
          self_type: parse_type("self"),
          instance_type: parse_type("instance"),
          class_type: parse_type("class")
        ) do |_|
          raise
        end
        assert_equal AST::Types::Name.new_instance(name: "::Numeric"), type
      end

      # If annotation is given and assigned type is incompatible with that, assign returns annotated type and yield an failure result
      yield_self do
        type = type_env.assign(
          gvar: :"$x",
          type: AST::Types::Name.new_instance(name: "::String"),
          self_type: parse_type("self"),
          instance_type: parse_type("instance"),
          class_type: parse_type("class")
        ) do |error|
          assert_predicate error, :failure?
        end
        assert_equal AST::Types::Name.new_instance(name: "::Numeric"), type
      end
    end
  end

  def test_const_without_annotation
    with_checker do |checker|
      const_env = ConstantEnv.new(factory: checker.factory, context: [RBS::Namespace.root], resolver: RBS::Resolver::ConstantResolver.new(builder: checker.factory.definition_builder))
      type_env = TypeEnv.new(subtyping: checker, const_env: const_env)

      # When constant type is known from const env

      yield_self do
        type = type_env.get(const: TypeName("Regexp")) {}
        assert_equal AST::Builtin.any_type, type
      end
    end
  end

  def test_const_with_annotation
    with_checker do |checker|
      const_env = ConstantEnv.new(factory: checker.factory, context: [], resolver: RBS::Resolver::ConstantResolver.new(builder: checker.factory.definition_builder))
      type_env = TypeEnv.new(subtyping: checker, const_env: const_env)

      type_env.set(const: TypeName("Regexp"), type: AST::Types::Name.new_instance(name: "::String"))

      yield_self do
        type = type_env.get(const: TypeName("Regexp"))
        assert_equal AST::Types::Name.new_instance(name: "::String"), type
      end
    end
  end

  def test_with_annotation_ivar
    with_checker do |checker|
      const_env = ConstantEnv.new(factory: checker.factory, context: [], resolver: RBS::Resolver::ConstantResolver.new(builder: checker.factory.definition_builder))
      original_env = TypeEnv.new(subtyping: checker, const_env: const_env)

      union_type = AST::Types::Union.build(types: [
        AST::Types::Name.new_instance(name: "::Integer"),
        AST::Types::Name.new_instance(name: "::String")
      ])

      original_env.set(ivar: :"@x", type: union_type)

      yield_self do
        type_env = original_env.with_annotations(
          ivar_types: {
            "@x": AST::Types::Name.new_instance(name: "::String")
          },
          self_type: parse_type("self"),
          instance_type: parse_type("instance"),
          class_type: parse_type("class")
        ) do |_, _, _|
          raise
        end

        assert_equal AST::Types::Name.new_instance(name: "::String"), type_env.get(ivar: :"@x") { raise }
      end

      yield_self do
        type_env = original_env.with_annotations(
          ivar_types: {
            "@x": AST::Types::Name.new_instance(name: "::Regexp")
          },
          self_type: parse_type("self"),
          instance_type: parse_type("instance"),
          class_type: parse_type("class")
        ) do |name, relation, error|
          assert_equal name, :"@x"
          assert_predicate error, :failure?
        end

        assert_equal AST::Types::Name.new_instance(name: "::Regexp"), type_env.get(ivar: :"@x") { raise }
      end

      yield_self do
        type_env = original_env.with_annotations(
          ivar_types: {
            "@y": AST::Types::Name.new_instance(name: "::String")
          },
          self_type: parse_type("self"),
          instance_type: parse_type("instance"),
          class_type: parse_type("class")
        ) do |_, _, _|
          raise
        end

        assert_equal AST::Types::Name.new_instance(name: "::String"), type_env.get(ivar: :"@y") { raise }
      end
    end
  end

  def test_with_annotation_gvar
    with_checker do |checker|
      const_env = ConstantEnv.new(factory: checker.factory, context: [], resolver: RBS::Resolver::ConstantResolver.new(builder: checker.factory.definition_builder))
      original_env = TypeEnv.new(subtyping: checker, const_env: const_env)

      union_type = AST::Types::Union.build(types: [
        AST::Types::Name.new_instance(name: "::Integer"),
        AST::Types::Name.new_instance(name: "::String")
      ])

      original_env.set(gvar: :"$x", type: union_type)

      yield_self do
        type_env = original_env.with_annotations(
          gvar_types: {
            "$x": AST::Types::Name.new_instance(name: "::String")
          },
          self_type: parse_type("self"),
          instance_type: parse_type("instance"),
          class_type: parse_type("class")
        ) do |_, _|
          raise
        end

        assert_equal AST::Types::Name.new_instance(name: "::String"), type_env.get(gvar: :"$x") { raise }
      end

      yield_self do
        type_env = original_env.with_annotations(
          gvar_types: {
            "$x": AST::Types::Name.new_instance(name: "::Regexp")
          },
          self_type: parse_type("self"),
          instance_type: parse_type("instance"),
          class_type: parse_type("class")
        ) do |name, relation, error|
          assert_equal name, :"$x"
          assert_predicate error, :failure?
        end

        assert_equal AST::Types::Name.new_instance(name: "::Regexp"), type_env.get(gvar: :"$x") { raise }
      end

      yield_self do
        type_env = original_env.with_annotations(
          gvar_types: {
            "$y": AST::Types::Name.new_instance(name: "::String")
          },
          self_type: parse_type("self"),
          instance_type: parse_type("instance"),
          class_type: parse_type("class")
        ) do |_, _|
          raise
        end

        assert_equal AST::Types::Name.new_instance(name: "::String"), type_env.get(gvar: :"$y") { raise }
      end
    end
  end

  def test_with_annotation_const
    with_checker do |checker|
      const_env = ConstantEnv.new(factory: checker.factory, context: [RBS::Namespace.root], resolver: RBS::Resolver::ConstantResolver.new(builder: checker.factory.definition_builder))
      original_env = TypeEnv.new(subtyping: checker, const_env: const_env)

      union_type = AST::Types::Union.build(types: [
        AST::Types::Name.new_instance(name: "::Integer"),
        AST::Types::Name.new_instance(name: "::String")
      ])

      original_env.set(const: TypeName("FOO"), type: union_type)

      yield_self do
        type_env = original_env.with_annotations(
          const_types: {
            TypeName("FOO") => AST::Types::Name.new_instance(name: "::String")
          },
          self_type: parse_type("self"),
          instance_type: parse_type("instance"),
          class_type: parse_type("class")
        ) do |_, _|
          raise
        end

        assert_equal AST::Types::Name.new_instance(name: "::String"),
                     type_env.get(const: TypeName("FOO")) { raise }
      end

      yield_self do
        type_env = original_env.with_annotations(
          const_types: {
            TypeName("FOO") => AST::Types::Name.new_instance(name: "::Regexp")
          },
          self_type: parse_type("self"),
          instance_type: parse_type("instance"),
          class_type: parse_type("class")
        ) do |name, relation, error|
          assert_equal name, TypeName("FOO")
          assert_predicate error, :failure?
        end

        assert_equal AST::Types::Name.new_instance(name: "::Regexp"),
                     type_env.get(const: TypeName("FOO")) { raise }
      end

      yield_self do
        type_env = original_env.with_annotations(
          const_types: {
            TypeName("String") => AST::Types::Name.new_instance(name: "::Regexp")
          },
          self_type: parse_type("self"),
          instance_type: parse_type("instance"),
          class_type: parse_type("class")
        ) do |name, relation, error|
          assert_equal name, TypeName("String")
          assert_predicate error, :failure?
        end

        assert_equal AST::Types::Name.new_instance(name: "::Regexp"),
                     type_env.get(const: TypeName("String")) { raise }
      end

      yield_self do
        type_env = original_env.with_annotations(
          const_types: {
            TypeName("BAR") => AST::Types::Name.new_instance(name: "::String")
          },
          self_type: parse_type("self"),
          instance_type: parse_type("instance"),
          class_type: parse_type("class")
        ) do |_, _, _|
          raise
        end

        assert_equal AST::Types::Name.new_instance(name: "::String"), type_env.get(const: TypeName("BAR")) { raise }
      end
    end
  end

  def test_build
    with_checker <<-RBS do |checker|
class X end
class Y end
$foo: String
    RBS
      const_env = ConstantEnv.new(factory: checker.factory, context: [], resolver: RBS::Resolver::ConstantResolver.new(builder: checker.factory.definition_builder))

      annotations = AST::Annotation::Collection.new(annotations: [
        AST::Annotation::VarType.new(name: :x, type: AST::Types::Name.new_instance(name: :X)),
        AST::Annotation::IvarType.new(name: :"@y", type: AST::Types::Name.new_instance(name: :Y)),
        AST::Annotation::ConstType.new(name: TypeName("Foo"), type: AST::Types::Name.new_instance(name: "::Integer")),
        AST::Annotation::ReturnType.new(type: AST::Types::Name.new_instance(name: :Z)),
        AST::Annotation::BlockType.new(type: AST::Types::Name.new_instance(name: :A)),
        AST::Annotation::Dynamic.new(names: [
          AST::Annotation::Dynamic::Name.new(name: :path, kind: :instance)
        ])
      ], factory: checker.factory, current_module: RBS::Namespace.root)

      env = TypeInference::TypeEnv.build(annotations: annotations,
                                         signatures: factory.env,
                                         subtyping: checker,
                                         const_env: const_env)

      assert_equal AST::Types::Name.new_instance(name: "::Y"), env.get(ivar: :"@y")
      assert_equal AST::Types::Name.new_instance(name: "::Integer"), env.get(const: TypeName("Foo"))
      assert_equal AST::Types::Name.new_instance(name: "::String"), env.get(gvar: :"$foo")
    end
  end
end
