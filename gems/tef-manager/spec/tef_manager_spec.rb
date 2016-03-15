# todo - decide if we want to do this kind of testing or not.


# require 'spec_helper'
# require 'tef/manager'
#
#
# describe 'Tef::Manager' do
#
#   context 'the gem has just been required' do
#
#     before(:all) do
#       # Making sure that this is a clean gem load (no constants already defined and no files skipped due
#       # to already being 'required'), regardless of what other tests or require statements might have
#       # already been executed.
#       old_tef_manager = TEF.send(:remove_const, :Manager) if TEF.const_defined?(:Manager)
#       $LOADED_FEATURES.delete_if { |file_path| file_path =~ /lib\/tef\/manager/ }
#
#       require 'tef/manager'
#     end
#
#     after(:all) do
#       # Restoring the module to whatever it looked like before these tests ran. Not worried about adjusting
#       # $LOADED_FEATURES since requiring the gem's files multiple times shouldn't significantly impact anything.
#       TEF::Manager = old_tef_manager if old_tef_manager
#     end
#
#
#     describe 'TEF level' do
#
#       it 'defines the Manager module' do
#         expect(TEF.const_defined?(:Manager)).to be true
#       end
#
#     end
#
#     describe 'TEF::Manager level' do
#
#       let(:nodule) { TEF::Manager }
#
#       it 'provides access to the ManagerNode class' do
#         expect(nodule.const_defined?(:ManagerNode)).to be true
#       end
#
#     end
#
#   end
# end
