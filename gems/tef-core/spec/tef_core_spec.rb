require 'spec_helper'
require 'tef/core'

# todo - either stop this kind of testing from breaking code coverage or remove it entirely
describe 'Tef::Core' do

  context 'the gem has just been required' do

    before(:all) do
      # Making sure that this is a clean gem load (no constants already defined and no files skipped due
      # to already being 'required'), regardless of what other tests or require statements might have
      # already been executed.
      @old_tef_core = TEF.send(:remove_const, :Core) if TEF.const_defined?(:Core)
      $LOADED_FEATURES.delete_if { |file_path| file_path =~ /lib\/tef\/core/ }

      require 'tef/core'
    end

    after(:all) do
      # Restoring the module to whatever it looked like before these tests ran. Not worried about adjusting
      # $LOADED_FEATURES since requiring the gem's files multiple times shouldn't significantly impact anything.
      TEF::Core = @old_tef_core if @old_tef_core
    end


    describe 'TEF level' do

      it 'defines the Core module' do
        expect(TEF.const_defined?(:Core)).to be true
      end

    end

    describe 'TEF::Core level' do

      let(:nodule) { TEF::Core }

      it 'provides access to the OuterComponent class' do
        expect(nodule.const_defined?(:OuterComponent)).to be true
      end

      it 'provides access to the InnerComponent class' do
        expect(nodule.const_defined?(:InnerComponent)).to be true
      end

    end

  end
end
