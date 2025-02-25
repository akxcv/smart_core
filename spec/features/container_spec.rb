# frozen_string_literal: true

describe SmartCore::Container do
  xspecify do # TODO: fix recursive locking
    class Container < SmartCore::Container
      namespace :kek do
        register(:pek, memoize: true) { 123 + 123 }
        register(:check) { 555 }
      end
    end

    container = Container.new

    expect(container.resolve(:kek).resolve(:pek)).to eq(246)

    class SubContainer < Container
      namespace :kek do
        namespace :bek do
          register(:lol) { 'lol' }
          register(:rand, memoize: true) { rand(5000) }
        end
      end
    end

    sub_container = SubContainer.new

    expect(sub_container.resolve(:kek).resolve(:bek).resolve(:lol)).to eq('lol')
    expect(sub_container.resolve(:kek).resolve(:pek)).to eq(246)
    expect(sub_container.resolve(:kek).resolve(:check)).to eq(555)

    memoized_value = sub_container.resolve(:kek).resolve(:bek).resolve(:rand)
    expect(sub_container.resolve(:kek).resolve(:bek).resolve(:rand)).to eq(memoized_value)

    # RELOAD 8-O
    sub_container.reload!
    expect(sub_container.resolve(:kek).resolve(:bek).resolve(:rand)).not_to eq(memoized_value)

    class AnyObject
      include SmartCore::Container::Mixin

      dependencies do
        namespace :kek do
          register(:pek) { 'test' }
          register(:fek) { 2 }
        end
      end
    end

    class SuperAnyObject < AnyObject
      dependencies do
        namespace :kek do
          register(:pek) { 'super_test' }
          register(:chmek) { nil }
        end
      end
    end

    any_object = AnyObject.new
    super_any_object = SuperAnyObject.new

    expect(any_object.container.resolve(:kek).resolve(:pek)).to eq('test')
    expect(AnyObject.container.resolve(:kek).resolve(:pek)).to eq('test')

    expect(super_any_object.container.resolve(:kek).resolve(:pek)).to eq('super_test')
    expect(SuperAnyObject.container.resolve(:kek).resolve(:pek)).to eq('super_test')

    expect(super_any_object.container.resolve(:kek).resolve(:fek)).to eq(2)
    expect(SuperAnyObject.container.resolve(:kek).resolve(:fek)).to eq(2)

    expect(super_any_object.container.resolve(:kek).resolve(:chmek)).to eq(nil)
    expect(SuperAnyObject.container.resolve(:kek).resolve(:chmek)).to eq(nil)

    expect { any_object.container.resolve(:kek).resolve(:chmek) }.to raise_error(
      SmartCore::Container::UnexistentDependencyError
    )
    expect { AnyObject.container.resolve(:kek).resolve(:chmek) }.to raise_error(
      SmartCore::Container::UnexistentDependencyError
    )

    expect(sub_container.frozen?).to eq(false)
    sub_container.freeze
    expect(sub_container.frozen?).to eq(true)

    expect { sub_container.register(:keka) { 123 } }.to raise_error(
      SmartCore::Container::FrozenRegistryError
    )
  end
end
